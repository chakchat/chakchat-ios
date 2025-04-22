//
//  GroupChatWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import Foundation
import CryptoKit

final class GroupChatWorker: GroupChatWorkerLogic {
    
    private let keychainManager: KeychainManagerBusinessLogic
    private let coreDataManager: CoreDataManagerProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let userService: UserServiceProtocol
    private let updateService: UpdateServiceProtocol
    private let fileService: FileStorageServiceProtocol
    private let groupUpdateService: GroupUpdateServiceProtocol
    private let secretGroupUpdateService: SecretGroupUpdateServiceProtocol
    
    init(
        keychainManager: KeychainManagerBusinessLogic,
        coreDataManager: CoreDataManagerProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol,
        userService: UserServiceProtocol,
        updateService: UpdateServiceProtocol,
        fileService: FileStorageServiceProtocol,
        groupUpdateService: GroupUpdateServiceProtocol,
        secretGroupUpdateService: SecretGroupUpdateServiceProtocol
    ) {
        self.keychainManager = keychainManager
        self.coreDataManager = coreDataManager
        self.userDefaultsManager = userDefaultsManager
        self.userService = userService
        self.updateService = updateService
        self.fileService = fileService
        self.groupUpdateService = groupUpdateService
        self.secretGroupUpdateService = secretGroupUpdateService
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
    
    func loadUsers(_ ids: [UUID], completion: @escaping (Result<[ProfileSettingsModels.ProfileUserData], any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        var users: [ProfileSettingsModels.ProfileUserData] = []
        let dispatchGroup = DispatchGroup()
        
        for user in ids {
            dispatchGroup.enter()
            userService.sendGetUserRequest(user, accessToken) { result in
                DispatchQueue.global().async {
                    defer { dispatchGroup.leave() }
                    switch result {
                    case .success(let response):
                        users.append(response.data)
                    case .failure(let failure):
                        print("Failed to fetch \(user) info")
                    }
                }
            }
        }
        dispatchGroup.notify(queue: .global()) {
            completion(.success(users))
        }
    }
    
    func sendTextMessage(_ chatID: UUID, _ message: String, _ replyTo: Int64?, _ chatType: ChatType, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        if chatType == .group {
            let request = ChatsModels.UpdateModels.SendMessageRequest(text: message, replyTo: replyTo)
            groupUpdateService.sendTextMessage(request, chatID, accessToken) { result in
                switch result {
                case .success(let response):
                    let data = response.data
                    completion(.success(data))
                    // сохраняем в coredata
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretGroup {
            let textContent = TextContent(replyTo, message, nil, nil, nil)
            if let jsonData = try? JSONEncoder().encode(textContent) {
                if let request = sealMessage(jsonData) {
                    secretGroupUpdateService.sendSecretMessage(request, chatID, accessToken) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let response):
                            let data = response.data
                            if let updateData = openMessage(data.content.payload, data.content.initializationVector, data.content.keyHash) {
                                completion(.success(updateData))
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
        if chatType == .group {
            groupUpdateService.deleteMessage(chatID, updateID, deleteMode, accessToken) { result in
                switch result {
                case .success(let response):
                    let data = response.data
                    completion(.success(data))
                    // сохраняем в coredata
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretGroup {
            let deleteContent = DeletedContent(deletedID: updateID, deletedMode: deleteMode)
            if let jsonData = try? JSONEncoder().encode(deleteContent) {
                if let request = sealMessage(jsonData) {
                    secretGroupUpdateService.sendSecretMessage(request, chatID, accessToken) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let response):
                            let data = response.data
                            if let updateData = openMessage(data.content.payload, data.content.initializationVector, data.content.keyHash) {
                                completion(.success(updateData))
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
        if chatType == .group {
            let request = ChatsModels.UpdateModels.EditMessageRequest(text: text)
            groupUpdateService.editTextMessage(chatID, updateID, request, accessToken) { result in
                switch result {
                case .success(let response):
                    let data = response.data
                    completion(.success(data))
                    // сохраняем в coredata
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretGroup {
            let editedContent = EditedContent(newText: text, messageID: updateID)
            if let jsonData = try? JSONEncoder().encode(editedContent) {
                if let request = sealMessage(jsonData) {
                    secretGroupUpdateService.sendSecretMessage(request, chatID, accessToken) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let response):
                            let data = response.data
                            if let updateData = openMessage(data.content.payload, data.content.initializationVector, data.content.keyHash) {
                                completion(.success(updateData))
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
        if chatType == .group {
            let request = ChatsModels.UpdateModels.FileMessageRequest(fileID: fileID, replyTo: replyTo)
            groupUpdateService.sendFileMessage(chatID, request, accessToken) { result in
                switch result {
                case .success(let response):
                    let data = response.data
                    completion(.success(data))
                    // сохраняем в coredata
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretGroup {
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
                        if let request = self.sealMessage(jsonData) {
                            self.secretGroupUpdateService.sendSecretMessage(request, chatID, accessToken) { result in
                                switch result {
                                case .success(let response):
                                    let data = response.data
                                    if let updateData = self.openMessage(data.content.payload, data.content.initializationVector, data.content.keyHash) {
                                        completion(.success(updateData))
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
        if chatType == .group {
            let request = ChatsModels.UpdateModels.ReactionRequest(reaction: reaction, messageID: messageID)
            groupUpdateService.sendReaction(chatID, request, accessToken) { result in
                switch result {
                case .success(let response):
                    let data = response.data
                    completion(.success(data))
                    // сохраняем в coredata
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretGroup {
            let reactionContent = ReactionContent(reaction: reaction, messageID: messageID)
            if let jsonData = try? JSONEncoder().encode(reactionContent) {
                if let request = self.sealMessage(jsonData) {
                    self.secretGroupUpdateService.sendSecretMessage(request, chatID, accessToken) { result in
                        switch result {
                        case .success(let response):
                            let data = response.data
                            if let updateData = self.openMessage(data.content.payload, data.content.initializationVector, data.content.keyHash) {
                                completion(.success(updateData))
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
        if chatType == .group {
            groupUpdateService.deleteReaction(chatID, updateID, accessToken) { result in
                switch result {
                case .success(let response):
                    let data = response.data
                    completion(.success(data))
                    // сохраняем в coredata
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretGroup {
            let deleteContent = DeletedContent(deletedID: updateID, deletedMode: .DeleteModeForAll)
            if let jsonData = try? JSONEncoder().encode(deleteContent) {
                if let request = sealMessage(jsonData) {
                    secretGroupUpdateService.sendSecretMessage(request, chatID, accessToken) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let response):
                            let data = response.data
                            if let updateData = openMessage(data.content.payload, data.content.initializationVector, data.content.keyHash) {
                                completion(.success(updateData))
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
    
    func fetchChat(_ userID: UUID) -> ChatsModels.GeneralChatModel.ChatData? {
        let chat = coreDataManager.fetchChatByMembers(userDefaultsManager.loadID(), userID, .personal)
        let mappedChat = mapFromCoredata(chat)
        return mappedChat
    }
    
    func getMyID() -> UUID {
        return userDefaultsManager.loadID()
    }
    
    private func mapFromCoredata(_ chat: Chat?) -> ChatsModels.GeneralChatModel.ChatData? {
        if let chat = chat {
            guard let chatID = chat.chatID,
                  let type = chat.type,
                  let members = chat.members,
                  let createdAt = chat.createdAt,
                  let info = chat.info else { return nil }
            let mappedInfo = try? JSONDecoder().decode(ChatsModels.GeneralChatModel.Info.self, from: info)
            if let mappedInfo = mappedInfo {
                let mappedChat = ChatsModels.GeneralChatModel.ChatData(
                    chatID: chatID,
                    type: ChatType(rawValue: type) ?? .personal,
                    members: members,
                    createdAt: createdAt,
                    info: mappedInfo
                )
                return mappedChat
            } else {
                print("Decoding error in mapFromCoredata")
                return nil
            }
        }
        return nil
    }
    
    private func sealMessage(_ json: Data) -> ChatsModels.SecretUpdateModels.SendMessageRequest? {
        guard let key = keychainManager.getString(key: KeychainManager.keyForSaveSecretKey) else {
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
    
    private func openMessage(_ payload: Data, _ iv: Data, _ sendedKeyHash: Data) -> UpdateData? {
        guard let key = keychainManager.getString(key: KeychainManager.keyForSaveSecretKey) else {
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
            
            return try? JSONDecoder().decode(UpdateData.self, from: decryptedData)
        }
        return nil
    }
}
