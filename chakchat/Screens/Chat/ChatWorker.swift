//
//  ChatWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import Foundation
import CryptoKit

// MARK: - ChatWorker
final class ChatWorker: ChatWorkerLogic {
        
    // MARK: - Properties
    private let keychainManager: KeychainManagerBusinessLogic
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let personalChatService: PersonalChatServiceProtocol
    private let secretPersonalChatService: SecretPersonalChatServiceProtocol
    private let updateService: UpdateServiceProtocol
    private let fileService: FileStorageServiceProtocol
    private let personalUpdateService: PersonalUpdateServiceProtocol
    private let secretPersonalUpdateService: SecretPersonalUpdateServiceProtocol
    
    // MARK: - Initialization
    init(
        keychainManager: KeychainManagerBusinessLogic,
        userDefaultsManager: UserDefaultsManagerProtocol,
        coreDataManager: CoreDataManagerProtocol,
        personalChatService: PersonalChatServiceProtocol,
        secretPersonalChatService: SecretPersonalChatServiceProtocol,
        updateService: UpdateServiceProtocol,
        fileService: FileStorageServiceProtocol,
        personalUpdateService: PersonalUpdateServiceProtocol,
        secretPersonalUpdateService: SecretPersonalUpdateServiceProtocol
    ) {
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
        self.coreDataManager = coreDataManager
        self.personalChatService = personalChatService
        self.secretPersonalChatService = secretPersonalChatService
        self.updateService = updateService
        self.fileService = fileService
        self.personalUpdateService = personalUpdateService
        self.secretPersonalUpdateService = secretPersonalUpdateService
    }
    
    func loadFirstMessages(_ chatID: UUID, _ from: Int64, _ to: Int64, completion: @escaping (Result<[UpdateData], any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        updateService.getUpdatesInRange(chatID, from, to, accessToken) { result in
            switch result {
            case .success(let response):
                completion(.success(response.updates))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func loadMoreMessages() {
        print("FAWF")
    }
    
    // MARK: - Public Methods
    func createChat(_ memberID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let request = ChatsModels.PersonalChat.CreateRequest(memberID: memberID)
        personalChatService.sendCreateChatRequest(request, accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    self.coreDataManager.createChat(response.data)
                }
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func sendTextMessage(
        _ chatID: UUID,
        _ message: String,
        _ replyTo: Int64?,
        _ chatType: ChatType,
        completion: @escaping (Result<UpdateData, any Error>) -> Void
    ) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        if chatType == .personal {
            let request = ChatsModels.UpdateModels.SendMessageRequest(text: message, replyTo: replyTo)
            personalUpdateService.sendTextMessage(request, chatID, accessToken) { result in
                switch result {
                case .success(let response):
                    let data = response.data
                    completion(.success(data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretPersonal {
            let textContent = TextContent(replyTo, message, nil, nil, nil)
            if let jsonData = try? JSONEncoder().encode(textContent) {
                if let request = sealMessage(chatID, jsonData) {
                    secretPersonalUpdateService.sendSecretMessage(request, chatID, accessToken) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let response):
                            let data = response.data
                            if let updateData = openMessage(chatID, data.content.payload, data.content.initializationVector, data.content.keyHash) {
                                guard let content = try? JSONDecoder().decode(TextContent.self, from: updateData) else {
                                    return
                                }
                                let update = UpdateData(
                                    data.chatID,
                                    data.updateID,
                                    .textMessage,
                                    data.senderID,
                                    data.createdAt,
                                    .textContent(content)
                                )
                                completion(.success(update))
                            }
                        case .failure(let failure):
                            completion(.failure(failure))
                        }
                    }
                }
            }
        }
    }
    
    func deleteMessage(_ chatID: UUID, _ updateID: Int64, _ deleteMode: DeleteMode, _ chatType: ChatType, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        if chatType == .personal {
            personalUpdateService.deleteMessage(chatID, updateID, deleteMode, accessToken) { result in
                switch result {
                case .success(let response):
                    let data = response.data
                    completion(.success(data))
                    // сохраняем в coredata
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretPersonal {
            let deleteContent = DeletedContent(deletedID: updateID, deletedMode: deleteMode)
            if let jsonData = try? JSONEncoder().encode(deleteContent) {
                if let request = sealMessage(chatID, jsonData) {
                    secretPersonalUpdateService.sendSecretMessage(request, chatID, accessToken) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let response):
                            let data = response.data
                            if let updateData = openMessage(chatID, data.content.payload, data.content.initializationVector, data.content.keyHash) {
                                guard let content = try? JSONDecoder().decode(DeletedContent.self, from: updateData) else {
                                    return
                                }
                                let update = UpdateData(
                                    data.chatID,
                                    data.updateID,
                                    .delete,
                                    data.senderID,
                                    data.createdAt,
                                    .deletedContent(content)
                                )
                                completion(.success(update))
                            }
                        case .failure(let failure):
                            completion(.failure(failure))
                        }
                    }
                }
            }
        }
    }
    
    func editTextMessage(_ chatID: UUID, _ updateID: Int64, _ text: String, _ chatType: ChatType, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        if chatType == .personal {
            let request = ChatsModels.UpdateModels.EditMessageRequest(text: text)
            personalUpdateService.editTextMessage(chatID, updateID, request, accessToken) { result in
                switch result {
                case .success(let response):
                    let data = response.data
                    completion(.success(data))
                    // сохраняем в coredata
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretPersonal {
            let editedContent = EditedContent(newText: text, messageID: updateID)
            if let jsonData = try? JSONEncoder().encode(editedContent) {
                if let request = sealMessage(chatID, jsonData) {
                    secretPersonalUpdateService.sendSecretMessage(request, chatID, accessToken) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let response):
                            let data = response.data
                            if let updateData = openMessage(chatID, data.content.payload, data.content.initializationVector, data.content.keyHash) {
                                guard let content = try? JSONDecoder().decode(EditedContent.self, from: updateData) else {
                                    return
                                }
                                let update = UpdateData(
                                    data.chatID,
                                    data.updateID,
                                    .textEdited,
                                    data.senderID,
                                    data.createdAt,
                                    .editedContent(content)
                                )
                                completion(.success(update))
                            }
                        case .failure(let failure):
                            completion(.failure(failure))
                        }
                    }
                }
            }
        }
    }
    
    func sendFileMessage(_ chatID: UUID, _ fileID: UUID, _ replyTo: Int64?, _ chatType: ChatType, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        if chatType == .personal {
            let request = ChatsModels.UpdateModels.FileMessageRequest(fileID: fileID, replyTo: replyTo)
            personalUpdateService.sendFileMessage(chatID, request, accessToken) { result in
                switch result {
                case .success(let response):
                    let data = response.data
                    completion(.success(data))
                    // сохраняем в coredata
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretPersonal {
            fileService.sendGetFileRequest(fileID, accessToken) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    let fileData = response.data
                    let fileContent = FileContent(
                        file: FileInfo(
                            fileID: fileData.fileId,
                            fileName: fileData.fileName,
                            mimeType: fileData.mimeType,
                            fileSize: fileData.fileSize,
                            fileURL: fileData.fileURL,
                            createdAt: fileData.createdAt
                        ),
                        replyTo: replyTo,
                        forwarded: nil,
                        reactions: nil
                    )
                    if let jsonData = try? JSONEncoder().encode(fileContent) {
                        if let request = self.sealMessage(chatID, jsonData) {
                            self.secretPersonalUpdateService.sendSecretMessage(request, chatID, accessToken) { result in
                                switch result {
                                case .success(let response):
                                    let data = response.data
                                    if let updateData = self.openMessage(chatID, data.content.payload, data.content.initializationVector, data.content.keyHash) {
                                        guard let content = try? JSONDecoder().decode(FileContent.self, from: updateData) else {
                                            return
                                        }
                                        let update = UpdateData(
                                            data.chatID,
                                            data.updateID,
                                            .file,
                                            data.senderID,
                                            data.createdAt,
                                            .fileContent(content)
                                        )
                                        completion(.success(update))
                                    }
                                case .failure(let failure):
                                    completion(.failure(failure))
                                }
                            }
                        }
                    }
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    
    func sendReaction(_ chatID: UUID, _ reaction: String, _ messageID: Int64, _ chatType: ChatType, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        if chatType == .personal {
            let request = ChatsModels.UpdateModels.ReactionRequest(reaction: reaction, messageID: messageID)
            personalUpdateService.sendReaction(chatID, request, accessToken) { result in
                switch result {
                case .success(let response):
                    let data = response.data
                    completion(.success(data))
                    // сохраняем в coredata
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretPersonal {
            let reactionContent = ReactionContent(reaction: reaction, messageID: messageID)
            if let jsonData = try? JSONEncoder().encode(reactionContent) {
                if let request = self.sealMessage(chatID, jsonData) {
                    self.secretPersonalUpdateService.sendSecretMessage(request, chatID, accessToken) { result in
                        switch result {
                        case .success(let response):
                            let data = response.data
                            if let updateData = self.openMessage(chatID, data.content.payload, data.content.initializationVector, data.content.keyHash) {
                                guard let content = try? JSONDecoder().decode(ReactionContent.self, from: updateData) else {
                                    return
                                }
                                let update = UpdateData(
                                    data.chatID,
                                    data.updateID,
                                    .reaction,
                                    data.senderID,
                                    data.createdAt,
                                    .reactionContent(content)
                                )
                                completion(.success(update))
                            }
                        case .failure(let failure):
                            completion(.failure(failure))
                        }
                    }
                }
            }
        }
    }
    
    func deleteReaction(_ chatID: UUID, _ updateID: Int64, _ chatType: ChatType, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        if chatType == .personal {
            personalUpdateService.deleteReaction(chatID, updateID, accessToken) { result in
                switch result {
                case .success(let response):
                    let data = response.data
                    completion(.success(data))
                    // сохраняем в coredata
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretPersonal {
            let deleteContent = DeletedContent(deletedID: updateID, deletedMode: .DeleteModeForAll)
            if let jsonData = try? JSONEncoder().encode(deleteContent) {
                if let request = sealMessage(chatID, jsonData) {
                    secretPersonalUpdateService.sendSecretMessage(request, chatID, accessToken) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let response):
                            let data = response.data
                            if let updateData = openMessage(chatID, data.content.payload, data.content.initializationVector, data.content.keyHash) {
                                guard let content = try? JSONDecoder().decode(DeletedContent.self, from: updateData) else {
                                    return
                                }
                                let update = UpdateData(
                                    data.chatID,
                                    data.updateID,
                                    .delete,
                                    data.senderID,
                                    data.createdAt,
                                    .deletedContent(content)
                                )
                                completion(.success(update))
                            }
                        case .failure(let failure):
                            completion(.failure(failure))
                        }
                    }
                }
            }
        }
    }
    
    func uploadImage(_ fileData: Data, _ fileName: String, _ mimeType: String, completion: @escaping (Result<SuccessModels.UploadResponse, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        fileService.sendFileUploadRequest(fileData, fileName, mimeType, accessToken) { result in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func setExpirationTime(_ chatID: UUID, _ expiration: String?, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let request = ChatsModels.SecretPersonalChat.ExpirationRequest(expiration: expiration)
        secretPersonalChatService.sendSetExpirationRequest(request, chatID, accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.coreDataManager.updateChat(response.data)
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func getMyID() -> UUID {
        return userDefaultsManager.loadID()
    }
    
    func getSecretKey(_ chatID: UUID) -> String? {
        let key = keychainManager.getSecretKey(chatID)
        return key
    }
    
    func saveSecretKey(_ key: String, _ chatID: UUID) -> Bool {
        let s = keychainManager.saveSecretKey(key, chatID)
        return s
    }
    
    private func sealMessage(_ chatID: UUID, _ json: Data) -> ChatsModels.SecretUpdateModels.SendMessageRequest? {
        guard let key = keychainManager.getSecretKey(chatID) else {
            return nil
        }
        let nonce = AES.GCM.Nonce()
        let hashedKey = SHA256.hash(data: Data(key.utf8))
        let symmetricKey = SymmetricKey(data: hashedKey)
        
        guard let sealedBox = try? AES.GCM.seal(json, using: symmetricKey, nonce: nonce) else {
            return nil
        }
        
        let combinedPayload = sealedBox.ciphertext + sealedBox.tag
        
        let digest = SHA256.hash(data: Data(key.utf8))
        let keyHash = digest.compactMap { String(format: "%02x", $0) }.joined()
        
        return ChatsModels.SecretUpdateModels
            .SendMessageRequest(
                payload: combinedPayload.base64EncodedData(),
                initializationVector: Data(nonce).base64EncodedData(),
                keyHash: Data(keyHash.utf8).base64EncodedData()
            )
    }
    
    internal func openMessage(_ chatID: UUID, _ payload: Data, _ iv: Data, _ sendedKeyHash: Data) -> Data? {
        guard let key = keychainManager.getSecretKey(chatID) else {
            return nil
        }
        
        let digest = SHA256.hash(data: Data(key.utf8))
        let keyHash = digest.compactMap { String(format: "%02x", $0) }.joined()
        let keyHashData = Data(keyHash.utf8).base64EncodedData()
        
        if keyHashData == sendedKeyHash {
            let symmetricKey = SymmetricKey(data: Data(SHA256.hash(data: Data(key.utf8))))
            guard let ivData = Data(base64Encoded: iv),
                  let payloadData = Data(base64Encoded: payload) else {
                return nil
            }
            guard let nonce = try? AES.GCM.Nonce(data: ivData) else { return nil }
            let ciphertext = payloadData.dropLast(16)
            let tag = payloadData.suffix(16)
            
            guard let sealedBox = try? AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag) else { return nil }
            guard let decryptedData = try? AES.GCM.open(sealedBox, using: symmetricKey) else { return nil }
            
            return decryptedData
        }
        return nil
    }
}
