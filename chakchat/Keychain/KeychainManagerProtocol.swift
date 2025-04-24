//
//  KeychainManagerProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 08.01.2025.
//

import Foundation

// MARK: - KeychainManagerProtocol
protocol KeychainManagerBusinessLogic {
    func save(key: String, value: UUID) -> Bool
    func save(key: String, value: String) -> Bool
    func saveSecretKey(_ secret: String, _ chatID: UUID) -> Bool
    func getUUID(key: String) -> UUID?
    func getString(key: String) -> String?
    func getSecretKey(_ chatID: UUID) -> String? 
    func delete(key: String) -> Bool
    func deleteTokens() -> Bool
}
