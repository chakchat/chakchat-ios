//
//  Chatinteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import Foundation
import OSLog
import Combine

// MARK: - ChatInteractor
final class ChatInteractor: ChatBusinessLogic {
    func sendTextMessage(_ message: String, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        print("Hello world")
    }
    
    
    // MARK: - Properties
    private let presenter: ChatPresentationLogic
    private let worker: ChatWorkerLogic
    private let eventManager: (EventPublisherProtocol & EventSubscriberProtocol)
    private let userData: ProfileSettingsModels.ProfileUserData
    private let errorHandler: ErrorHandlerLogic
    private let logger: OSLog
    
    private var chatData: ChatsModels.GeneralChatModel.ChatData?
    var onRouteBack: (() -> Void)?
    var onRouteToProfile: ((ProfileSettingsModels.ProfileUserData, ChatsModels.GeneralChatModel.ChatData?, ProfileConfiguration) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        presenter: ChatPresentationLogic,
        worker: ChatWorkerLogic,
        userData: ProfileSettingsModels.ProfileUserData,
        eventManager: (EventPublisherProtocol & EventSubscriberProtocol),
        errorHandler: ErrorHandlerLogic,
        logger: OSLog,
        chatData: ChatsModels.GeneralChatModel.ChatData?
    ) {
        self.presenter = presenter
        self.worker = worker
        self.userData = userData
        self.eventManager = eventManager
        self.errorHandler = errorHandler
        self.logger = logger
        self.chatData = chatData
        
        subscribeToEvents()
    }
    // если обычный чат еще не создан то он не может быть секретным
    func passUserData() {
        let myID = worker.getMyID()
        if let chatD = chatData {
            presenter.passUserData(chatD, userData, chatD.type.rawValue == "personal_secret", myID)
        } else {
            presenter.passUserData(nil, userData, false, myID)
        }
    }
    
    func loadFirstMessages(completion: @escaping (Result<[MessageForKit], Error>) -> Void) {
        if let cd = chatData {
            worker.loadFirstMessages(cd.chatID, 1, 200) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    let sortedUpdates = data.sorted { $0.updateID < $1.updateID }
                    let mappedSortedUpdates = self.mapToKit(sortedUpdates)
                    completion(.success(mappedSortedUpdates))
                case .failure(let failure):
                    completion(.failure(failure))
                    print(failure)
                }
            }
        }
    }
    
    func loadMoreMessages() {
        worker.loadMoreMessages()
    }
        
    // MARK: - Public Methods
    func createChat(_ memberID: UUID, completion: @escaping () -> Void) {
        worker.createChat(memberID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                os_log("Chat with member(%@) created", log: logger, type: .default, memberID as CVarArg)
                chatData = ChatsModels.GeneralChatModel.ChatData(
                    chatID: data.chatID,
                    type: data.type,
                    members: data.members,
                    createdAt: data.createdAt,
                    info: data.info
                )
                let event = CreatedChatEvent(
                    chatID: data.chatID,
                    type: data.type,
                    members: data.members,
                    createdAt: data.createdAt,
                    info: data.info
                )
                eventManager.publish(event: event)
                completion()
            case .failure(let failure):
                _ = errorHandler.handleError(failure)
                os_log("Failed to create chat with member(%@):\n", log: logger, type: .fault, memberID as CVarArg)
                print(failure)
            }
        }
    }
    
    func sendTextMessage(_ message: String, _ replyTo: Int64?, completion: @escaping (Bool) -> Void)  {
        if chatData == nil {
            createChat(userData.id) { [weak self] in
                self?.send(message, replyTo) { isSent in
                    completion(isSent)
                }
            }
        } else {
            send(message, replyTo) { isSent in
                completion(isSent)
            }
        }
    }
    
    func deleteMessage(_ updateID: Int64, _ deleteMode: DeleteMode, completion: @escaping (Bool) -> Void) {
        guard let cd = chatData else { return }
        worker.deleteMessage(cd.chatID, updateID, deleteMode) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let failure):
                completion(false)
                print(failure)
            }
        }
    }
    
    func editTextMessage(_ updateID: Int64, _ text: String, completion: @escaping (Bool) -> Void) {
        guard let cd = chatData else { return }
        worker.editTextMessage(cd.chatID, updateID, text) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let failure):
                completion(false)
                print(failure)
            }
        }
    }
    
    func sendFileMessage(_ fileID: UUID, _ replyTo: Int64?, completion: @escaping (Bool) -> Void) {
        guard let cd = chatData else { return }
        worker.sendFileMessage(cd.chatID, fileID, replyTo) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let failure):
                completion(false)
                print(failure)
            }
        }
    }
    
    func sendReaction(_ reaction: String, _ messageID: Int64, completion: @escaping (Bool) -> Void) {
        guard let cd = chatData else { return }
        worker.sendReaction(cd.chatID, reaction, messageID) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let failure):
                completion(false)
                print(failure)
            }
        }
    }
    
    func deleteReaction(_ updateID: Int64, completion: @escaping (Bool) -> Void) {
        guard let cd = chatData else { return }
        worker.deleteReaction(cd.chatID, updateID) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let failure):
                completion(false)
                print(failure)
            }
        }
    }
    
    func setExpirationTime(_ expiration: String?) {
        guard let chatID = chatData?.chatID else { return }
        worker.setExpirationTime(chatID, expiration) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(_):
                os_log("Setted expiration time with member(%@)", log: logger, type: .default, userData.id as CVarArg)
            case .failure(let failure):
                _ = errorHandler.handleError(failure)
                os_log("Failed to set expiration time with member(%@)", log: logger, type: .default, userData.id as CVarArg)
                print(failure)
            }
        }
    }
    
    func saveSecretKey(_ key: String) {
        if worker.saveSecretKey(key) {
            os_log("Secret key saved", log: logger, type: .default)
        } else {
            os_log("Failed to save secret key", log: logger, type: .fault)
            presenter.showSecretKeyFail()
        }
    }
    
    private func send(_ message: String, _ replyTo: Int64?, completion: @escaping (Bool) -> Void) {
        guard let cd = chatData else { return }
        worker.sendTextMessage(cd.chatID, message, replyTo) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(_):
                    os_log("Sent message in chat(%@)", log: self.logger, type: .default, cd.chatID as CVarArg)
                    completion(true)
                case .failure(let failure):
                    os_log("Failed to send message in chat(%@)", log: self.logger, type: .default, cd.chatID as CVarArg)
                    _ = self.errorHandler.handleError(failure)
                    completion(false)
                }
            }
        }
    }
    
    private func subscribeToEvents() {
        eventManager.subscribe(BlockedChatEvent.self) { [weak self] event in
            self?.handleChatBlock(event)
        }.store(in: &cancellables)
    }
    
    func handleChatBlock(_ event: BlockedChatEvent) {
        presenter.changeInputBar(event.blocked)
    }
    
    // MARK: - Routing
    func routeBack() {
        onRouteBack?()
    }
    // чат не может быть секретным если даже обычный еще не был создан
    func routeToProfile() {
        if let chatD = chatData {
            let profileConfiguration = ProfileConfiguration(isSecret: chatD.type.rawValue == "personal_secret", fromGroupChat: false)
            onRouteToProfile?(userData, chatD, profileConfiguration)
        } else {
            let profileConfiguration = ProfileConfiguration(isSecret: false, fromGroupChat: false)
            onRouteToProfile?(userData, nil, profileConfiguration)
        }
    }
    
    private func mapToKit(_ updates: [UpdateData]) -> [MessageForKit] {
        var mappedUpdates: [MessageForKit] = []
        for update in updates {
            switch update.type {
            case .textMessage:
                if case .textContent(let textContent) = update.content {
                    var edited: ChatTextEditedContent?
                    var reactions: [ChatReactionContent]?
                    if let editedC = textContent.edited {
                        if case .editedContent(let editedContent) = editedC.content {
                            let mappedEditedContent = ChatTextEditedContent(
                                newText: editedContent.newText,
                                messageID: editedContent.messageID
                            )
                            edited = mappedEditedContent
                        }
                    }
                    if let reactionsC = textContent.reactions {
                        var mappedReactions: [ChatReactionContent] = []
                        for reaction in reactionsC {
                            if case .reactionContent(let reactionContent) = reaction.content {
                                let mappedReaction = ChatReactionContent(
                                    reaction: reactionContent.reaction,
                                    messageID: reactionContent.messageID
                                )
                                mappedReactions.append(mappedReaction)
                            }
                        }
                        reactions = mappedReactions
                    }
                    
                    let mappedTextContent = ChatTextContent(
                        text: textContent.text,
                        edited: edited,
                        replyTo: textContent.replyTo,
                        reactions: reactions
                    )
                    let mappedTextUpdate = MessageForKit(
                        sender: SenderPerson(senderId: update.senderID.uuidString, displayName: ""),
                        messageId: String(update.updateID),
                        sentDate: update.createdAt,
                        kind: .text(edited?.newText ?? textContent.text),
                        status: .sent,
                        isEdited: false,
                        chatID: update.chatID,
                        updateID: update.updateID,
                        contentType: .text,
                        content: .text(mappedTextContent)
                    )
                    mappedUpdates.append(mappedTextUpdate)
                }
            case .textEdited:
                if case .editedContent(let editedContent) = update.content {
                    let mappedTextEditContent = ChatTextEditedContent(
                        newText: editedContent.newText,
                        messageID: editedContent.messageID
                    )
                    let mappedTextEditUpdate = MessageForKit(
                        sender: SenderPerson(senderId: update.senderID.uuidString, displayName: ""),
                        messageId: String(update.updateID),
                        sentDate: update.createdAt,
                        kind: .text(editedContent.newText),
                        status: .edited,
                        isEdited: true,
                        chatID: update.chatID,
                        updateID: update.updateID,
                        contentType: .textEdited,
                        content: .textEdited(mappedTextEditContent)
                    )
                    mappedUpdates.append(mappedTextEditUpdate)
                }
            case .file: // пока что не поддерживается
                if case .fileContent(let fileContent) = update.content {
                    let mappedFileContent = ChatFileContent(
                        fileID: fileContent.fileID,
                        fileName: fileContent.fileName,
                        mimeType: fileContent.mimeType,
                        fileSize: fileContent.fileSize,
                        fileURL: fileContent.fileURL,
                        createdAt: fileContent.createdAt
                    )
                    let mappedFileUpdate = MessageForKit(
                        sender: SenderPerson(senderId: update.senderID.uuidString, displayName: ""),
                        messageId: String(update.updateID),
                        sentDate: update.createdAt,
                        kind: .text(""),
                        status: .sent,
                        isEdited: false,
                        chatID: update.chatID,
                        updateID: update.updateID,
                        contentType: .file,
                        content: .file(mappedFileContent)
                    )
                    mappedUpdates.append(mappedFileUpdate)
                }
            case .reaction:
                if case .reactionContent(let reactionContent) = update.content  {
                    let mappedReactionContent = ChatReactionContent(
                        reaction: reactionContent.reaction,
                        messageID: reactionContent.messageID
                    )
                    let mappedReactionUpdate = MessageForKit(
                        sender: SenderPerson(senderId: update.senderID.uuidString, displayName: ""),
                        messageId: String(update.updateID),
                        sentDate: update.createdAt,
                        kind: .emoji(mappedReactionContent.reaction),
                        status: .sent,
                        isEdited: false,
                        chatID: update.chatID,
                        updateID: update.updateID,
                        contentType: .reaction,
                        content: .reaction(mappedReactionContent)
                    )
                    mappedUpdates.append(mappedReactionUpdate)
                }
            case .delete:
                if case .deletedContent(let deletedContent) = update.content {
                    let mappedDeletedContent = ChatDeletedUpdateContent(
                        deletedID: deletedContent.deletedID,
                        deleteMode: deletedContent.deletedMode
                    )
                    let mappedDeletedUpdate = MessageForKit(
                        sender: SenderPerson(senderId: update.senderID.uuidString, displayName: ""),
                        messageId: String(update.updateID),
                        sentDate: update.createdAt,
                        kind: .custom(DeleteKind(deleteMessageID: deletedContent.deletedID, deleteMode: deletedContent.deletedMode)),
                        status: .sent,
                        isEdited: false,
                        chatID: update.chatID,
                        updateID: update.updateID,
                        contentType: .deleted,
                        content: .deleted(mappedDeletedContent)
                    )
                    mappedUpdates.append(mappedDeletedUpdate)
                }
            }
        }
        return mappedUpdates
    }
}
