//
//  SuccessModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 08.01.2025.
//

import Foundation

// MARK: - SuccessModels
enum SuccessModels {
    
    // MARK: - Tokens Models
    struct Tokens: Codable {
        let accessToken: String
        let refreshToken: String
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
        }
    }
    
    // MARK: - VerifySignupData Models
    struct VerifySignupData: Codable {}
    
    // MARK: - SendCodeSigninData Models
    struct SendCodeSigninData: Codable {
        let signinKey: UUID
        
        enum CodingKeys: String, CodingKey {
            case signinKey = "signin_key"
        }
    }
    
    // MARK: - SendCodeSignupData Models
    struct SendCodeSignupData: Codable {
        let signupKey: UUID
        
        enum CodingKeys: String, CodingKey {
            case signupKey = "signup_key"
        }
    }
    
    struct UploadResponse: Codable {
        let fileName: String
        let fileSize: Int
        let mimeType: String
        let fileId: UUID
        let fileURL: URL
        let createdAt: String
        
        enum CodingKeys: String, CodingKey {
            case fileName = "file_name"
            case fileSize = "file_size"
            case mimeType = "mime_type"
            case fileId = "file_id"
            case fileURL = "file_url"
            case createdAt = "created_at"
        }
    }
    
    struct UploadPartResponse: Codable {
        let eTag: String
        
        enum CodingKeys: String, CodingKey {
            case eTag = "e_tag"
        }
    }
    
    struct UploadInitResponse: Codable {
        let uploadID: String
        
        enum CodingKeys: String, CodingKey {
            case uploadID = "upload_id"
        }
    }
    
    struct EmptyResponse: Codable {}
}
