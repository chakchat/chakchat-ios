//
//  Chatinteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import Foundation
import OSLog
import Combine
import UIKit
import MessageKit
import PhotosUI

// MARK: - ChatInteractor
final class ChatInteractor: ChatBusinessLogic {

    // MARK: - Properties
    private let presenter: ChatPresentationLogic
    private let worker: ChatWorkerLogic
    private let eventManager: (EventPublisherProtocol & EventSubscriberProtocol)
    private let userData: ProfileSettingsModels.ProfileUserData
    private let errorHandler: ErrorHandlerLogic
    private let logger: OSLog
    
    private var usersInfo: [ProfileSettingsModels.ProfileUserData] = []
    
    private var chatData: ChatsModels.GeneralChatModel.ChatData?
    var onRouteBack: (() -> Void)?
    var onRouteToProfile: ((ProfileSettingsModels.ProfileUserData, ChatsModels.GeneralChatModel.ChatData?, ProfileConfiguration) -> Void)?
    var onPresentForwardVC: ((UUID, Int64, ForwardType, ChatType) -> Void)?
    
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
    
    func loadFirstMessages(completion: @escaping (Result<[any MessageType], any Error>) -> Void) {
        if let cd = chatData {
            worker.loadFirstMessages(cd.chatID, 1, 200) { [weak self] result in
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
    
    func sendTextMessage(_ message: String, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, any Error>) -> Void)  {
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
    
    func deleteMessage(_ updateID: Int64, _ deleteMode: DeleteMode, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let chatData = chatData else { return }
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
        guard let chatData = chatData else { return }
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
        guard let chatData = chatData else { return }
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
    
    func sendReaction(_ reaction: String, _ messageID: Int64, completion: @escaping (Result<UpdateData, Error>)-> Void) {
        guard let chatData = chatData else { return }
        worker.sendReaction(chatData.chatID, reaction, messageID) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func deleteReaction(_ updateID: Int64, completion: @escaping (Result<UpdateData, Error>) -> Void) {
        guard let chatData = chatData else { return }
        worker.deleteReaction(chatData.chatID, updateID) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func forwardMessage(_ message: Int64, _ forwardType: ForwardType) {
        guard let chatData = chatData else { return }
        if forwardType == .text {
            onPresentForwardVC?(chatData.chatID, message, .text, .personal)
        }
        if forwardType == .file {
            onPresentForwardVC?(chatData.chatID, message, .file, .personal)
        }
    }
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.0) else {
            return
        }
        let fileName = "\(UUID().uuidString).jpeg"
        let mimeType = "image/jpeg"
        worker.uploadImage(data, fileName, mimeType) { [weak self] result in
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
    
    func uploadVideo(_ videoURL: URL, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let data = try? Data(contentsOf: videoURL) else { return }
        let fileName = "\(UUID().uuidString).mp4"
        let mimeType = "video/mp4"
        worker.uploadImage(data, fileName, mimeType) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let fileMetaData):
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
                os_log("Uploading user video failed:\n", log: logger, type: .fault)
                print(failure)
                completion(.failure(failure))
            }
        }
    }
    
    func uploadFile(_ fileURL: URL, _ mimeType: String?, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let data = try? Data(contentsOf: fileURL),
              let mimeType = mimeType else { return }
        let fileName = "\(UUID().uuidString).mp4"
        worker.uploadImage(data, fileName, mimeType) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let fileMetaData):
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
                os_log("Uploading user file failed:\n", log: logger, type: .fault)
                print(failure)
                completion(.failure(failure))
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
    
    private func send(_ message: String, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let cd = chatData else { return }
        worker.sendTextMessage(cd.chatID, message, replyTo) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    os_log("Sent message in chat(%@)", log: self.logger, type: .default, cd.chatID as CVarArg)
                    completion(.success(data))
                case .failure(let failure):
                    os_log("Failed to send message in chat(%@)", log: self.logger, type: .default, cd.chatID as CVarArg)
                    _ = self.errorHandler.handleError(failure)
                    completion(.failure(failure))
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
            mappedTextUpdate.isForwarded = tc.forwarded ?? false
            mappedTextUpdate.editedMessage = tc.edited?.content.newText
            if let reactions = tc.reactions {
                var reactionsDict: [Int64: String] = [:]
                for reaction in reactions {
                    reactionsDict.updateValue(reaction.content.reaction, forKey: reaction.updateID)
                }
                mappedTextUpdate.reactions = reactionsDict
            }
            mappedTextUpdate.curUserPickedReaction = nil // на этапе ViewController'a
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
            mappedFileUpdate.isForwarded = fc.forwarded ?? false
            if fc.file.mimeType == "image/jpeg" {
                mappedFileUpdate.kind = .photo(
                    PhotoMediaItem(
                        url: fc.file.fileURL,
                        image: ImageCacheManager.shared.getImage(for: fc.file.fileURL as NSURL),
                        placeholderImage: UIImage(),
                        shimmer: nil,
                        size: CGSize(width: 200, height: 200),
                        status: .sent
                    )
                )
            }
            else if fc.file.mimeType == "video/mp4" {
                let thumbnail = generateThumbnail(for: fc.file.fileURL)
                mappedFileUpdate.kind =
                    .video(
                        PhotoMediaItem(
                            url: fc.file.fileURL,
                            image: thumbnail,
                            placeholderImage: UIImage(systemName: "play.circle.fill")!,
                            shimmer: nil,
                            size: thumbnail.size,
                            status: .sent
                        )
                    )
            } else {
                mappedFileUpdate.kind = .text(fc.file.fileURL.absoluteString)
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
                let mappedFileUpdate = mapToFileMessage(update)
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
    
    private func generateThumbnail(for videoURL: URL) -> UIImage {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let maxSize = CGSize(width: 200, height: 200)
        generator.maximumSize = maxSize
        
        do {
            let cgImage = try generator.copyCGImage(at: CMTime(value: 1, timescale: 60), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            let scaledImage = thumbnail.scaledToFit(maxSize: maxSize)
            return scaledImage
            
        } catch {
            return UIImage(systemName: "play.circle.fill")!
            
        }
    }
}
