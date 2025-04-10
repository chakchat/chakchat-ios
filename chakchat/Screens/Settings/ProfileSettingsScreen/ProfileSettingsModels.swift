//
//  ProfileSettingsModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.01.2025.
//

import Foundation
import UIKit

// MARK: - ProfileSettingsModels
enum ProfileSettingsModels {
    struct ProfileUserData: Codable {
        let id: UUID
        let name: String
        let username: String
        let phone: String?
        let photo: URL?
        let dateOfBirth: String?
        let createdAt: Date
    }
    
    struct Users: Codable {
        let users: [ProfileSettingsModels.ProfileUserData]
    }
    
    struct ChangeableProfileUserData: Codable {
        let name: String
        let username: String
        let dateOfBirth: String?
        
        enum CodingKeys: String, CodingKey {
            case name = "name"
            case username = "username"
            case dateOfBirth = "date_of_birth"
        }
    }
    
    struct NewPhotoRequest: Codable {
        let photoID: UUID
        
        enum CodingKeys: String, CodingKey {
            case photoID = "photo_id"
        }
    }
}
