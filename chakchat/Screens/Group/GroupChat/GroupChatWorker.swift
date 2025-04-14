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
    private let updateService: UpdateServiceProtocol
    
    init(
        keychainManager: KeychainManagerBusinessLogic,
        coreDataManager: CoreDataManagerProtocol,
        updateService: UpdateServiceProtocol
    ) {
        self.keychainManager = keychainManager
        self.coreDataManager = coreDataManager
        self.updateService = updateService
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
    
    func sendTextMessage(_ message: String) {
        print("Sended text message: \(message)")
    }
}
