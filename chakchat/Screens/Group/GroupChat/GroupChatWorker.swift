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
    private let userService: UserServiceProtocol
    private let updateService: UpdateServiceProtocol
    private let groupUpdateService: GroupUpdateServiceProtocol
    
    init(
        keychainManager: KeychainManagerBusinessLogic,
        coreDataManager: CoreDataManagerProtocol,
        userService: UserServiceProtocol,
        updateService: UpdateServiceProtocol,
        groupUpdateService: GroupUpdateServiceProtocol
    ) {
        self.keychainManager = keychainManager
        self.coreDataManager = coreDataManager
        self.userService = userService
        self.updateService = updateService
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
}
