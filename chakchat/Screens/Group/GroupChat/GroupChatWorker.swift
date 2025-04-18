//
//  GroupChatWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import Foundation

final class GroupChatWorker: GroupChatWorkerLogic {    
    private let keychainManager: KeychainManagerBusinessLogic
    private let coreDataManager: CoreDataManagerProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let userService: UserServiceProtocol
    private let updateService: UpdateServiceProtocol
    private let fileService: FileStorageServiceProtocol
    private let groupUpdateService: GroupUpdateServiceProtocol
    
    init(
        keychainManager: KeychainManagerBusinessLogic,
        coreDataManager: CoreDataManagerProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol,
        userService: UserServiceProtocol,
        updateService: UpdateServiceProtocol,
        fileService: FileStorageServiceProtocol,
        groupUpdateService: GroupUpdateServiceProtocol
    ) {
        self.keychainManager = keychainManager
        self.coreDataManager = coreDataManager
        self.userDefaultsManager = userDefaultsManager
        self.userService = userService
        self.updateService = updateService
        self.fileService = fileService
        self.groupUpdateService = groupUpdateService
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
    
    func sendTextMessage(_ chatID: UUID, _ message: String, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
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
    }
    
    func deleteMessage(_ chatID: UUID, _ updateID: Int64, _ deleteMode: DeleteMode, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
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
    }
    
    func editTextMessage(_ chatID: UUID, _ updateID: Int64, _ text: String, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
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
    }
    
    func sendFileMessage(_ chatID: UUID, _ fileID: UUID, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
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
    }
    
    func sendReaction(_ chatID: UUID, _ reaction: String, _ messageID: Int64, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
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
    }
    
    func deleteReaction(_ chatID: UUID, _ updateID: Int64, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
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
}
