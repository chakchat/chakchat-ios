//
//  SignupModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.01.2025.
//

import Foundation

// MARK: - Signup Models
enum SignupModels {
    
    struct SignupRequest: Codable {
        let signupKey: UUID
        let name: String
        let username: String
        
        enum CodingKeys: String, CodingKey {
            case signupKey = "signup_key"
            case name = "name"
            case username = "username"
        }
    }
    
    struct UserExistsResponse: Codable {
        let userExists: Bool
        
        enum CodingKeys: String, CodingKey {
            case userExists = "user_exists"
        }
    }
}
