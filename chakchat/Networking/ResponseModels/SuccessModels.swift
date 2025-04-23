//
//  SuccessModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 08.01.2025.
//

import Foundation

// MARK: - SuccessModels
enum SuccessModels {
    
    struct Tokens: Codable {
        let accessToken: String
        let refreshToken: String
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
        }
    }
    
    
    struct SendCodeSigninData: Codable {
        let signinKey: UUID
        
        enum CodingKeys: String, CodingKey {
            case signinKey = "signin_key"
        }
    }
    
    struct SendCodeSignupData: Codable {
        let signupKey: UUID
        
        enum CodingKeys: String, CodingKey {
            case signupKey = "signup_key"
        }
    }
    
    struct UploadResponse: Codable {
        let fileName: String
        let fileSize: Int64
        let mimeType: String
        let fileId: UUID
        let fileURL: URL
        let createdAt: Date
        
        enum CodingKeys: String, CodingKey {
            case fileName = "file_name"
            case fileSize = "file_size"
            case mimeType = "mime_type"
            case fileId = "file_id"
            case fileURL = "file_url"
            case createdAt = "created_at"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            fileName = try container.decode(String.self, forKey: .fileName)
            fileSize = try container.decode(Int64.self, forKey: .fileSize)
            mimeType = try container.decode(String.self, forKey: .mimeType)
            fileId = try container.decode(UUID.self, forKey: .fileId)
            fileURL = try container.decode(URL.self, forKey: .fileURL)
            
            let dateString = try container.decode(String.self, forKey: .createdAt)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let date = formatter.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .createdAt,
                    in: container,
                    debugDescription: "Date string does not match format expected by formatter."
                )
            }
            createdAt = date
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
