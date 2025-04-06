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
    private let updateService: PersonalUpdateServiceProtocol
    
    init(
        keychainManager: KeychainManagerBusinessLogic,
        coreDataManager: CoreDataManagerProtocol,
        updateService: PersonalUpdateServiceProtocol
    ) {
        self.keychainManager = keychainManager
        self.coreDataManager = coreDataManager
        self.updateService = updateService
    }
    // implemented soon
    func sendTextMessage(_ message: String) {
        print("Sended text message: \(message)")
    }
}
