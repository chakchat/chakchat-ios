//
//  GroupChatInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit
import OSLog
import Combine
import MessageKit

final class GroupChatInteractor: GroupChatBusinessLogic {
    
    private let presenter: GroupChatPresentationLogic
    private let worker: GroupChatWorkerLogic
    private let eventSubscriber: EventSubscriberProtocol
    private let errorHandler: ErrorHandlerLogic
    private var chatData: ChatsModels.GeneralChatModel.ChatData
    private var usersInfo: [ProfileSettingsModels.ProfileUserData] = []
    private let logger: OSLog
    
    private var cancellables = Set<AnyCancellable>()
    
    var onRouteBack: (() -> Void)?
    var onRouteToGroupProfile: ((ChatsModels.GeneralChatModel.ChatData) -> Void)?
    var onRouteToUserProfile: ((ProfileSettingsModels.ProfileUserData, ChatsModels.GeneralChatModel.ChatData?, ProfileConfiguration) -> Void)?
    var onRouteToMyProfile: (() -> Void)?
    
    init(
        presenter: GroupChatPresentationLogic,
        worker: GroupChatWorkerLogic,
        eventSubscriber: EventSubscriberProtocol,
        errorHandler: ErrorHandlerLogic,
        chatData: ChatsModels.GeneralChatModel.ChatData,
        logger: OSLog
    ) {
        self.presenter = presenter
        self.worker = worker
        self.eventSubscriber = eventSubscriber
        self.errorHandler = errorHandler
        self.chatData = chatData
        self.logger = logger
        
        subscribeToEvents()
    }
    
    func passChatData() {
        presenter.passChatData(chatData, worker.getMyID())
    }
       
    
    func loadFirstMessages(completion: @escaping (Result<[any MessageType], any Error>) -> Void) {
        worker.loadFirstMessages(chatData.chatID, 1, 200) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                let sortedUpdates = data.sorted { $0.updateID < $1.updateID }
                let mappedSortedUpdates = self.mapToMessageType(sortedUpdates)
                completion(.success(mappedSortedUpdates))
            case .failure(let failure):
                completion(.failure(failure))
                print(failure)
            }
        }
    }
    
    func loadUsers(completion: @escaping (Result<[ProfileSettingsModels.ProfileUserData], Error>) -> Void) {
        worker.loadUsers(chatData.members) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let users):
                self.usersInfo = users
                completion(.success(usersInfo))
            case .failure(let failure):
                completion(.failure(failure))
                print(failure)
            }
        }
    }
    
    func sendTextMessage(_ message: String, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        worker.sendTextMessage(chatData.chatID, message, replyTo) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func deleteMessage(_ updateID: Int64, _ deleteMode: DeleteMode, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        worker.deleteMessage(chatData.chatID, updateID, deleteMode) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func editTextMessage(_ updateID: Int64, _ text: String, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        worker.editTextMessage(chatData.chatID, updateID, text) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func sendFileMessage(_ fileID: UUID, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, Error>) -> Void) {
        worker.sendFileMessage(chatData.chatID, fileID, replyTo) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
                print(failure)
            }
        }
    }
    
    func sendReaction(_ reaction: String, _ messageID: Int64, completion: @escaping (Bool) -> Void) {
        worker.sendReaction(chatData.chatID, reaction, messageID) { result in
            switch result {
            case .success(let data):
                completion(true)
            case .failure(let failure):
                completion(false)
                print(failure)
            }
        }
    }
    
    func deleteReaction(_ updateID: Int64, completion: @escaping (Bool) -> Void) {
        worker.deleteReaction(chatData.chatID, updateID) { result in
            switch result {
            case .success(let data):
                completion(true)
            case .failure(let failure):
                completion(false)
                print(failure)
            }
        }
    }
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.0) else {
            return
        }
        let fileName = "\(UUID().uuidString).jpeg"
        worker.uploadImage(data, fileName, "image/jpeg") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let fileMetaData):
                ImageCacheManager.shared.saveImage(image, for: fileMetaData.fileURL as NSURL)
                sendFileMessage(fileMetaData.fileId, nil) { result in
                    switch result {
                    case .success(let fileUpdate):
                        completion(.success(fileUpdate))
                    case .failure(let failure):
                        completion(.failure(failure))
                    }
                }
            case .failure(let failure):
                _ = errorHandler.handleError(failure)
                os_log("Uploading user image failed:\n", log: logger, type: .fault)
                print(failure)
                completion(.failure(failure))
            }
        }
    }
    
    func handleAddedMemberEvent(_ event: AddedMemberEvent) {
        print("Handle new member")
    }
    
    func handleDeletedMemberEvent(_ event: DeletedMemberEvent) {
        if let i = chatData.members.firstIndex(of: event.memberID) {
            chatData.members.remove(at: i)
        }
    }
    
    func routeBack() {
        onRouteBack?()
    }
    
    func routeToUserProfile(_ userID: UUID) {
        if userID == worker.getMyID() {
            onRouteToMyProfile?()
        } else {
            let chatData = worker.fetchChat(userID)
            guard let userID = usersInfo.firstIndex(where: {$0.id == userID}) else { return }
            let user = usersInfo[userID]
            let profileConfiguration = ProfileConfiguration(isSecret: false, fromGroupChat: true)
            onRouteToUserProfile?(user, chatData, profileConfiguration)
        }
    }
    
    func routeToChatProfile() {
        onRouteToGroupProfile?(chatData)
    }
    
    private func subscribeToEvents() {
        eventSubscriber.subscribe(AddedMemberEvent.self) { [weak self] event in
            self?.handleAddedMemberEvent(event)
        }.store(in: &cancellables)
        eventSubscriber.subscribe(DeletedMemberEvent.self) { [weak self] event in
            self?.handleDeletedMemberEvent(event)
        }.store(in: &cancellables)
    }
    
    func mapToTextMessage(_ update: UpdateData) -> GroupTextMessage {
        var mappedTextUpdate = GroupTextMessage()
        if case .textContent(let tc) = update.content {
            mappedTextUpdate.sender = GroupSender(senderId: update.senderID.uuidString, displayName: getSenderName(update.senderID), avatar: nil)
            mappedTextUpdate.messageId = String(update.updateID)
            mappedTextUpdate.sentDate = update.createdAt
            mappedTextUpdate.kind = .text(tc.edited?.content.newText ?? tc.text)
            mappedTextUpdate.text = tc.edited?.content.newText ?? tc.text
            mappedTextUpdate.replyTo = nil // на этапе ViewController'a
            mappedTextUpdate.replyToID = tc.replyTo
            mappedTextUpdate.isEdited = tc.edited != nil ? true : false
            mappedTextUpdate.editedMessage = tc.edited?.content.newText
            if let reactions = tc.reactions {
                var reactionsDict: [Int64: String] = [:]
                for reaction in reactions {
                    reactionsDict.updateValue(reaction.content.reaction, forKey: reaction.updateID)
                }
                mappedTextUpdate.reactions = reactionsDict
            }
            mappedTextUpdate.status = .sent
        }
        return mappedTextUpdate
    }
    
    func mapToEditedMessage(_ update: UpdateData) -> GroupTextMessageEdited {
        var mappedTextEditedUpdate = GroupTextMessageEdited()
        if case .editedContent(let ec) = update.content {
            mappedTextEditedUpdate.sender = GroupSender(senderId: update.senderID.uuidString, displayName: getSenderName(update.senderID), avatar: nil)
            mappedTextEditedUpdate.messageId = String(update.updateID)
            mappedTextEditedUpdate.sentDate = update.createdAt
            mappedTextEditedUpdate.kind = .custom(Kind.GroupTextMessageEditedKind)
            mappedTextEditedUpdate.newText = ec.newText
            mappedTextEditedUpdate.oldTextUpdateID = ec.messageID
            mappedTextEditedUpdate.status = .sent
        }
        return mappedTextEditedUpdate
    }
    
    func mapToFileMessage(_ update: UpdateData) -> GroupFileMessage {
        var mappedFileUpdate = GroupFileMessage()
        if case .fileContent(let fc) = update.content {
            mappedFileUpdate.sender = GroupSender(senderId: update.senderID.uuidString, displayName: getSenderName(update.senderID), avatar: nil)
            mappedFileUpdate.messageId = String(update.updateID)
            mappedFileUpdate.sentDate = update.createdAt
            mappedFileUpdate.fileID = fc.file.fileID
            mappedFileUpdate.fileName = fc.file.fileName
            mappedFileUpdate.mimeType = fc.file.mimeType
            mappedFileUpdate.fileSize = fc.file.fileSize
            mappedFileUpdate.fileURL = fc.file.fileURL
            if fc.file.mimeType == "image/jpeg" {
                mappedFileUpdate.kind = .photo(
                    PhotoMediaItem(
                        url: fc.file.fileURL,
                        image: ImageCacheManager.shared.getImage(for: fc.file.fileURL as NSURL),
                        placeholderImage: UIImage(),
                        shimmer: nil,
                        size: CGSize(width: 150, height: 150),
                        status: .sent
                    )
                )
            }
            if let reactions = fc.reactions {
                var reactionsDict: [Int64: String] = [:]
                for reaction in reactions {
                    reactionsDict.updateValue(reaction.content.reaction, forKey: reaction.updateID)
                }
                mappedFileUpdate.reactions = reactionsDict
            }
            mappedFileUpdate.status = .sent
        }
        return mappedFileUpdate
    }
    
    private func mapToMessageType(_ updates: [UpdateData]) -> [MessageType] {
        var mappedUpdates: [MessageType] = []
        for update in updates {
            switch update.type {
            case .textMessage:
                let mappedTextUpdate = mapToTextMessage(update)
                mappedUpdates.append(mappedTextUpdate)
            case .textEdited:
                let mappedEditedTextUpdate = mapToEditedMessage(update)
                mappedUpdates.append(mappedEditedTextUpdate)
            case .file:
                var mappedFileUpdate = mapToFileMessage(update)
                mappedUpdates.append(mappedFileUpdate)
            case .reaction:
                var mappedReactionUpdate: GroupReaction!
                if case .reactionContent(let rc) = update.content {
                    mappedReactionUpdate.sender = GroupSender(senderId: update.senderID.uuidString, displayName: getSenderName(update.senderID), avatar: nil)
                    mappedReactionUpdate.messageId = String(update.updateID)
                    mappedReactionUpdate.sentDate = update.createdAt
                    mappedReactionUpdate.kind = .custom(Kind.GroupReactionKind)
                    mappedReactionUpdate.onMessageID = rc.messageID
                    mappedReactionUpdate.reaction = rc.reaction
                    mappedReactionUpdate.status = .sent
                }
                mappedUpdates.append(mappedReactionUpdate)
            case .delete:
                var mappedDeleteUpdate: GroupMessageDelete = GroupMessageDelete()
                if case .deletedContent(let dc) = update.content {
                    mappedDeleteUpdate.sender = GroupSender(senderId: update.senderID.uuidString, displayName: getSenderName(update.senderID), avatar: nil)
                    mappedDeleteUpdate.messageId = String(update.updateID)
                    mappedDeleteUpdate.sentDate = update.createdAt
                    mappedDeleteUpdate.kind = .custom(Kind.GroupMessageDeleteKind)
                    mappedDeleteUpdate.deletedMessageID = dc.deletedID
                    mappedDeleteUpdate.deleteMode = dc.deletedMode
                    mappedDeleteUpdate.status = .sent
                }
                mappedUpdates.append(mappedDeleteUpdate)
            }
        }
        return mappedUpdates
    }
    
    private func getSenderName(_ senderID: UUID) -> String {
        if let userID = usersInfo.firstIndex(where: {$0.id == senderID}) {
            let user = usersInfo[userID]
            return user.name
        }
        return ""
    }
}
