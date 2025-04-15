//
//  ChatWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import Foundation

// MARK: - ChatWorker
final class ChatWorker: ChatWorkerLogic {
        
    // MARK: - Properties
    private let keychainManager: KeychainManagerBusinessLogic
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let personalChatService: PersonalChatServiceProtocol
    private let secretPersonalChatService: SecretPersonalChatServiceProtocol
    private let updateService: UpdateServiceProtocol
    private let personalUpdateService: PersonalUpdateServiceProtocol
    
    // MARK: - Initialization
    init(
        keychainManager: KeychainManagerBusinessLogic,
        userDefaultsManager: UserDefaultsManagerProtocol,
        coreDataManager: CoreDataManagerProtocol,
        personalChatService: PersonalChatServiceProtocol,
        secretPersonalChatService: SecretPersonalChatServiceProtocol,
        updateService: UpdateServiceProtocol,
        personalUpdateService: PersonalUpdateServiceProtocol
    ) {
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
        self.coreDataManager = coreDataManager
        self.personalChatService = personalChatService
        self.secretPersonalChatService = secretPersonalChatService
        self.updateService = updateService
        self.personalUpdateService = personalUpdateService
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
                self.coreDataManager.createChat(response.data)
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func sendTextMessage(_ chatID: UUID, _ message: String, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let request = ChatsModels.UpdateModels.SendMessageRequest(text: message, replyTo: replyTo)
        personalUpdateService.sendTextMessage(request, chatID, accessToken) { result in
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
    }
    
    func editTextMessage(_ chatID: UUID, _ updateID: Int64, _ text: String, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
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
    }
    
    func sendFileMessage(_ chatID: UUID, _ fileID: UUID, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
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
    }
    
    func sendReaction(_ chatID: UUID, _ reaction: String, _ messageID: Int64, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
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
    }
    
    func deleteReaction(_ chatID: UUID, _ updateID: Int64, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
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
    
    func saveSecretKey(_ key: String) -> Bool{
        let s = keychainManager.save(key: key, value: KeychainManager.keyForSaveSecretKey)
        return s
    }
}
