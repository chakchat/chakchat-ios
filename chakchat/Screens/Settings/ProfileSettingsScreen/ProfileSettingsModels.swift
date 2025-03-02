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
        let phone: String
        let photo: URL?
        let dateOfBirth: String?
        let createdAt: Date
    }
    
    struct Users: Codable {
        let users: [ProfileSettingsModels.ProfileUserData]
    }
    
    struct ChangeableProfileUserData: Codable {
        var name: String
        var username: String
        var dateOfBirth: String?
    }
    
    struct NewPhotoRequest: Codable {
        let photoID: UUID
        
        enum CodingKeys: String, CodingKey {
            case photoID = "photo_id"
        }
    }
}
