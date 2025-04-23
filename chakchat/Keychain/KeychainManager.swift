//
//  KeychainManager.swift
//  chakchat
//
//  Created by Кирилл Исаев on 08.01.2025.
//

import Foundation

// MARK: - KeychainManager
final class KeychainManager: KeychainManagerBusinessLogic {
    
    // MARK: - Constants
    static let keyForSaveSigninCode: String = "signinCode"
    static let keyForSaveSignupCode: String = "signupCode"
    static let keyForSaveAccessToken: String = "accessToken"
    static let keyForSaveRefreshToken: String = "refreshToken"
    static let keyForSaveSecretKey: String = "secretKey"
    
    // MARK: - Saving Methods
    // for verification code and other data with UUID type
    @discardableResult
    func save(key: String, value: UUID) -> Bool {
        return save(key: key, value: value.uuidString)
    }
    
    func saveSecretKey(_ secret: String, _ chatID: UUID) -> Bool {
        let key = keyForSecret(chatID: chatID)
        return save(key: key, value: secret)
    }
    
    func getSecretKey(_ chatID: UUID) -> String? {
        let key = keyForSecret(chatID: chatID)
        return getString(key: key)
    }
    
    // for phone and other data with string type
    @discardableResult
    func save(key: String, value: String) -> Bool {
        
        guard let data = value.data(using: .utf8) else { return false }
        
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        print(value)
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Public Methods
    // for verification code and other data with UUID type
    func getUUID(key: String) -> UUID? {
        guard let valueString = getString(key: key) else { return nil }
        return UUID(uuidString: valueString)
    }
    
    // for phone and other data with string type
    func getString(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data,
              let valueString = String(data: data, encoding: .utf8) else { return nil }
        return valueString
    }
    
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    func deleteTokens() -> Bool {
        return (delete(key: KeychainManager.keyForSaveAccessToken) && delete(key: KeychainManager.keyForSaveRefreshToken))
    }
    
    private func keyForSecret(chatID: UUID) -> String {
        return "secretKey_\(chatID.uuidString)"
    }
}

// MARK: - Keychain Models
enum Keychain {
    enum KeychainError: Error {
        case saveError
        case getError
        case deleteError
    }
}

