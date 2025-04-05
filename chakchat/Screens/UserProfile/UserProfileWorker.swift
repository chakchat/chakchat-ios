//
//  UserProfileWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import UIKit

// MARK: - UserProfileWorker
final class UserProfileWorker: UserProfileWorkerLogic {
    
    // MARK: - Properties
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let keychainManager: KeychainManagerBusinessLogic
    private let coreDataManager: CoreDataManagerProtocol
    private let personalChatService: PersonalChatServiceProtocol
    private let secretPersonalChatService: SecretPersonalChatServiceProtocol
    private let messagingService: UpdateServiceProtocol
    
    // MARK: - Initialization
    init(
        userDefaultsManager: UserDefaultsManagerProtocol,
        keychainManager: KeychainManagerBusinessLogic,
        coreDataManager: CoreDataManagerProtocol,
        personalChatService: PersonalChatServiceProtocol,
        secretPersonalChatService: SecretPersonalChatServiceProtocol,
        messagingService: UpdateServiceProtocol
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.keychainManager = keychainManager
        self.coreDataManager = coreDataManager
        self.personalChatService = personalChatService
        self.secretPersonalChatService = secretPersonalChatService
        self.messagingService = messagingService
    }
    
    // MARK: - Public Methods
    func createSecretChat(_ memberID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let request = ChatsModels.PersonalChat.CreateRequest(memberID: memberID)
        secretPersonalChatService.sendCreateChatRequest(request, accessToken) { [weak self] result in
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

    func blockChat(_ chatID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        personalChatService.sendBlockChatRequest(chatID, accessToken) { [weak self] result in
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
    
    func unblockChat(_ chatID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        personalChatService.sendUnblockRequest(chatID, accessToken) { [weak self] result in
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
    
    func deleteChat(_ chatID: UUID, _ deleteMode: DeleteMode, completion: @escaping (Result<EmptyResponse, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        personalChatService.sendDeleteChatRequest(chatID, deleteMode, accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.coreDataManager.deleteChat(chatID)
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func searchForExistingChat(_ memberID: UUID) -> Chat? {
        let myID = getMyID()
        let chat = coreDataManager.fetchChatByMembers(myID, memberID, ChatType.personal)
        return chat != nil ? chat : nil
    }
    
    func getMyID() -> UUID {
        let myID = userDefaultsManager.loadID()
        return myID
    }
    
    func changeSecretKey(_ key: String) -> Bool {
        let s = keychainManager.save(key: key, value: KeychainManager.keyForSaveSecretKey)
        return s
    }
    
    func searchMessages() {
        /// имплементация позже
    }
    
    func switchNotification() {
        /// имплементация позже
    }
}
