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
    private let coreDataManager: CoreDataManagerProtocol
    private let personalChatService: PersonalChatServiceProtocol
    private let updateService: UpdateServiceProtocol
    
    // MARK: - Initialization
    init(
        keychainManager: KeychainManagerBusinessLogic,
        coreDataManager: CoreDataManagerProtocol,
        personalChatService: PersonalChatServiceProtocol,
        updateService: UpdateServiceProtocol
    ) {
        self.keychainManager = keychainManager
        self.coreDataManager = coreDataManager
        self.personalChatService = personalChatService
        self.updateService = updateService
    }
    
    // MARK: - Public Methods
    func createChat(_ memberID: UUID, completion: @escaping (Result<ChatsModels.PersonalChat.Response, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let request = ChatsModels.PersonalChat.CreateRequest(memberID: memberID)
        personalChatService.sendCreateChatRequest(request, accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                coreDataManager.createPersonalChat(response.data)
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func sendTextMessage(_ message: String) {
        print("Sended message: \(message)")
    }
}
