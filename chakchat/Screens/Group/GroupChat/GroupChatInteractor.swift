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
import PhotosUI

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
    var onPresentForwardVC: ((UUID, Int64, ForwardType, ChatType) -> Void)?
    
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
    
    func pollNewMessages(_ from: Int64, completion: @escaping (Result<[any MessageType], any Error>) -> Void) {
        
        worker.loadFirstMessages(chatData.chatID, from, 200) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                let sortedUpdates = data.sorted { $0.updateID < $1.updateID }
                let mappedSortedUpdates = self.mapToMessageType(sortedUpdates)
                completion(.success(mappedSortedUpdates))
            case .failure(let error):
                completion(.failure(error))
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
        worker.sendTextMessage(chatData.chatID, message, replyTo, chatData.type) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func deleteMessage(_ updateID: Int64, _ deleteMode: DeleteMode, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        worker.deleteMessage(chatData.chatID, updateID, deleteMode, chatData.type) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func editTextMessage(_ updateID: Int64, _ text: String, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        worker.editTextMessage(chatData.chatID, updateID, text, chatData.type) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func sendFileMessage(_ fileID: UUID, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, Error>) -> Void) {
        worker.sendFileMessage(chatData.chatID, fileID, replyTo, chatData.type) { result in
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
        worker.sendReaction(chatData.chatID, reaction, messageID, chatData.type) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func deleteReaction(_ updateID: Int64, completion: @escaping (Result<UpdateData, Error>) -> Void) {
        worker.deleteReaction(chatData.chatID, updateID, chatData.type) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func forwardMessage(_ message: Int64, _ forwardType: ForwardType) {
        if forwardType == .text {
            onPresentForwardVC?(chatData.chatID, message, .text, .group)
        }
        if forwardType == .file {
            onPresentForwardVC?(chatData.chatID, message, .file, .group)
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
        let fileName = "\(videoURL.lastPathComponent)"
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
    
    func uploadAudio(_ audioURL: URL, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let data = try? Data(contentsOf: audioURL) else { return }
        let fileName = audioURL.lastPathComponent
        let mimeType = audioURL.pathExtension
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
                os_log("Uploading user audio failed:\n", log: logger, type: .fault)
                print(failure)
                completion(.failure(failure))
            }
        }
    }
    
    func uploadFile(_ fileURL: URL, _ mimeType: String?, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let data = try? Data(contentsOf: fileURL),
              let mimeType = mimeType else { return }
        let fileName = "\(fileURL.lastPathComponent)"
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
    
    func checkForSecretKey() {
        let key = worker.getSecretKey(chatData.chatID)
        if key == nil {
            presenter.showInputSecretKeyAlert()
        }
    }
    
    func saveSecretKey(_ key: String) {
        let s = worker.saveSecretKey(key, chatData.chatID)
        if s {
            onSecretKeyChanged()
            os_log("Saved secret key(%@)", log: logger, type: .default, key as CVarArg)
        } else {
            os_log("Failed to save secret key(%@)", log: logger, type: .fault, key as CVarArg)
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
    
    func handleUpdateGroupPhoto(_ event: UpdatedGroupPhotoEvent) {
        if case .group(var info) = chatData.info {
            info.groupPhoto = event.photoURL
            chatData.info = .group(info)
        }
        DispatchQueue.main.async {
            self.presenter.updateGroupPhoto(event.photo)
        }
    }
    
    func handleUpdateGroupInfo(_ event: UpdatedGroupInfoEvent) {
        if case .group(var info) = chatData.info {
            info.name = event.name
            info.description = event.description
            chatData.info = .group(info)
        }
        DispatchQueue.main.async {
            self.presenter.updateGroupInfo(event.name, event.description)
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
        eventSubscriber.subscribe(UpdatedGroupPhotoEvent.self) { [weak self] event in
            self?.handleUpdateGroupPhoto(event)
        }.store(in: &cancellables)
        eventSubscriber.subscribe(UpdatedGroupInfoEvent.self) { [weak self] event in
            self?.handleUpdateGroupInfo(event)
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
            mappedTextUpdate.isForwarded = tc.forwarded ?? false
            mappedTextUpdate.editedMessage = tc.edited?.content.newText
            if let reactions = tc.reactions {
                var reactionsDict: [Int64: String] = [:]
                for reaction in reactions {
                    reactionsDict.updateValue(reaction.content.reaction, forKey: reaction.updateID)
                }
                if !reactionsDict.isEmpty {
                    mappedTextUpdate.reactions = reactionsDict
                }
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
                let photo = ImageCacheManager.shared.getImage(for: fc.file.fileURL as NSURL)
                mappedFileUpdate.kind = .photo(
                    PhotoMediaItem(
                        url: fc.file.fileURL,
                        image: photo,
                        placeholderImage: UIImage(),
                        shimmer: nil,
                        size: photo?.size ?? CGSize(width: 300, height: 300),
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
                mappedFileUpdate.kind = .text("\(fc.file.fileURL.absoluteString)#\(fc.file.fileName)#\(fc.file.mimeType)")
            }
            if let reactions = fc.reactions {
                var reactionsDict: [Int64: String] = [:]
                for reaction in reactions {
                    reactionsDict.updateValue(reaction.content.reaction, forKey: reaction.updateID)
                }
                if !reactionsDict.isEmpty {
                    mappedFileUpdate.reactions = reactionsDict
                }
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
                var mappedReactionUpdate = GroupReaction()
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
            case .secret:
                if let secretUpdate = resolveSecretType(update) {
                    let sub = mapToMessageType(
                        [UpdateData(
                            secretUpdate.chatID,
                            secretUpdate.updateID,
                            secretUpdate.type,
                            secretUpdate.senderID,
                            secretUpdate.createdAt,
                            secretUpdate.content
                        )]
                    )
                    mappedUpdates.append(sub[0])
                } else  {
                    let encryptedUpdate = EncryptedMessage(
                        sender: GroupSender(senderId: update.senderID.uuidString, displayName: getSenderName(update.senderID), avatar: nil),
                        messageId: String(update.updateID),
                        sentDate: update.createdAt,
                        kind: .text("ENCRYPTED"),
                        dummy: 52 // чтобы отличалась от любой другой ячейки реализующей протокол MessageType
                    )
                    mappedUpdates.append(encryptedUpdate)
                }
            }
        }
        return mappedUpdates
    }
    
    private func resolveSecretType(_ update: UpdateData) -> UpdateData? {
        guard case .secretContent(let sc) = update.content else { return nil }
        guard let dectyptedData = worker.openMessage(chatData.chatID, sc.payload, sc.initializationVector, sc.keyHash) else { return nil}
        if let textContent = try? JSONDecoder().decode(TextContent.self, from: dectyptedData) {
            return UpdateData(
                update.chatID,
                update.updateID,
                .textMessage,
                update.senderID,
                update.createdAt,
                .textContent(textContent)
            )
        }
        if let editedContent = try? JSONDecoder().decode(EditedContent.self, from: dectyptedData) {
            return UpdateData(
                update.chatID,
                update.updateID,
                .textEdited,
                update.senderID,
                update.createdAt,
                .editedContent(editedContent)
            )
        }
        if let fileContent = try? JSONDecoder().decode(FileContent.self, from: dectyptedData) {
            return UpdateData(
                update.chatID,
                update.updateID,
                .file,
                update.senderID,
                update.createdAt,
                .fileContent(fileContent)
            )
        }
        if let reactionContent = try? JSONDecoder().decode(ReactionContent.self, from: dectyptedData) {
            return UpdateData(
                update.chatID,
                update.updateID,
                .reaction,
                update.senderID,
                update.createdAt,
                .reactionContent(reactionContent)
            )
        }
        if let deletedContent = try? JSONDecoder().decode(DeletedContent.self, from: dectyptedData) {
            return UpdateData(
                update.chatID,
                update.updateID,
                .delete,
                update.senderID,
                update.createdAt,
                .deletedContent(deletedContent)
            )
        }
        return nil
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
    
    private func downloadAudio(_ remoteURL: URL) async throws -> URL {
        let (data, _) = try await URLSession.shared.data(from: remoteURL)

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = remoteURL.lastPathComponent
        let localURL = tempDir.appendingPathComponent(fileName)

        try data.write(to: localURL)
        return localURL
    }
    
    private func onSecretKeyChanged() {
        NotificationCenter.default.post(name: .secretKeyUpdated, object: nil)
    }
}
