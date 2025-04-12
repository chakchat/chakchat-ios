//
//  ChatsScreenModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 26.02.2025.
//

import Foundation

// MARK: - ChatsModels
enum ChatsModels {
    
    enum GeneralChatModel {
        
        struct ChatsData: Codable {
            let chats: [ChatData]
        }
        
        struct ChatInfo {
            let chatName: String
            let chatPhotoURL: URL?
        }
        
        struct PersonalInfo: Codable {
            let blockedBy: [UUID]?
            
            enum CodingKeys: String, CodingKey {
                case blockedBy = "blocked_by"
            }
        }
        /// сделал кастомный декодер потому что по умолчанию пустая строка не может преобразоваться в URL?
        struct GroupInfo: Codable {
            let admin: UUID
            let name: String
            let description: String?
            let groupPhoto: URL?
            
            enum CodingKeys: String, CodingKey {
                case admin = "admin_id"
                case name = "name"
                case description = "description"
                case groupPhoto = "group_photo"
            }
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                admin = try container.decode(UUID.self, forKey: .admin)
                name = try container.decode(String.self, forKey: .name)
                description = try container.decodeIfPresent(String.self, forKey: .description)
                if let groupPhotoString = try container.decodeIfPresent(String.self, forKey: .groupPhoto), !groupPhotoString.isEmpty {
                    groupPhoto = URL(string: groupPhotoString)
                } else {
                    groupPhoto = nil
                }
            }
        }

        struct SecretPersonalInfo: Codable {
            let expiration: String?
            
            enum CodingKeys: String, CodingKey {
                case expiration = "expiration"
            }
        }
        
        struct SecretGroupInfo: Codable {
            let admin: UUID
            let name: String
            let description: String?
            let groupPhoto: URL?
            let expiration: String?
            
            enum CodingKeys: String, CodingKey {
                case admin = "admin"
                case name = "name"
                case description = "description"
                case groupPhoto = "group_photo"
                case expiration = "expiration"
            }
        }
        
        struct ChatData: Codable {
            let chatID: UUID
            let type: ChatType
            var members: [UUID]
            let createdAt: Date
            let info: Info
            
            enum CodingKeys: String, CodingKey {
                case chatID = "chat_id"
                case type = "type"
                case members = "members"
                case createdAt = "created_at"
                case info = "info"
            }
            
            init(chatID: UUID, type: ChatType, members: [UUID], createdAt: Date, info: Info) {
                self.chatID = chatID
                self.type = type
                self.members = members
                self.createdAt = createdAt
                self.info = info
            }
            
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                chatID = try container.decode(UUID.self, forKey: .chatID)
                type = try container.decode(ChatType.self, forKey: .type)
                members = try container.decode([UUID].self, forKey: .members)
                createdAt = try container.decode(Date.self, forKey: .createdAt)
                
                switch type {
                case .personal:
                    let personalInfo = try container.decode(PersonalInfo.self, forKey: .info)
                    info = .personal(personalInfo)
                case .personalSecret:
                    let personalSecretInfo = try container.decode(SecretPersonalInfo.self, forKey: .info)
                    info = .secretPersonal(personalSecretInfo)
                case .group:
                    let groupInfo = try container.decode(GroupInfo.self, forKey: .info)
                    info = .group(groupInfo)
                case .groupSecret:
                    let secretGroupInfo = try container.decode(SecretGroupInfo.self, forKey: .info)
                    info = .secretGroup(secretGroupInfo)
                }
            }
            
            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(chatID, forKey: .chatID)
                try container.encode(type, forKey: .type)
                try container.encode(members, forKey: .members)
                try container.encode(createdAt, forKey: .createdAt)
                
                switch info {
                case .personal(let personalInfo):
                    try container.encode(personalInfo, forKey: .info)
                case .group(let groupInfo):
                    try container.encode(groupInfo, forKey: .info)
                case .secretPersonal(let secretPersonalInfo):
                    try container.encode(secretPersonalInfo, forKey: .info)
                case .secretGroup(let secretGroupInfo):
                    try container.encode(secretGroupInfo, forKey: .info)
                }
            }
            
        }
        
        enum Info: Codable {
            case personal(PersonalInfo)
            case group(GroupInfo)
            case secretPersonal(SecretPersonalInfo)
            case secretGroup(SecretGroupInfo)
        }
        
        struct Preview: Codable {
            let updateID: Int64
            let type: UpdateDataType
            let chatID: UUID
            let senderID: UUID
            let createdAt: Date
            let content: Content?
            
            enum CodingKeys: String, CodingKey {
                case updateID = "update_id"
                case type = "type"
                case chatID = "chat_id"
                case senderID = "sender_id"
                case createdAt = "created_at"
                case content = "content"
            }
        }
        
        enum Content: Codable {
            case text(TextContent)
            case file(FileContent)
            case reaction(Reaction)
            
            enum CodingKeys: String, CodingKey {
                case text
                case file
                case reaction
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                if let textContent = try container.decodeIfPresent(TextContent.self, forKey: .text) {
                    self = .text(textContent)
                } else if let fileContent = try container.decodeIfPresent(FileContent.self, forKey: .file) {
                    self = .file(fileContent)
                } else if let reactionContent = try container.decodeIfPresent(Reaction.self, forKey: .reaction) {
                    self = .reaction(reactionContent)
                } else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown content type"))
                }
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case .text(let textContent):
                    try container.encode(textContent, forKey: .text)
                case .file(let fileContent):
                    try container.encode(fileContent, forKey: .file)
                case .reaction(let reactionContent):
                    try container.encode(reactionContent, forKey: .reaction)
                }
            }
        }
        
        struct TextContent: Codable {
            let text: String
            let replyTo: Int64?
            let forwarded: Bool
            let reactions: [Reaction]?
            
            enum CodingKeys: String, CodingKey {
                case text = "text"
                case replyTo = "reply_to"
                case forwarded = "forwarded"
                case reactions = "reactions"
            }
        }
        
        struct FileContent: Codable {
            let file: SuccessModels.UploadResponse
            let replyTo: UUID
            let forwarded: Bool
            let reactions: [Reaction]?
            
            enum CodingKeys: String, CodingKey {
                case file
                case replyTo = "reply_to"
                case forwarded
                case reactions
            }
        }
        
        struct Reaction: Codable {
            let updateID: Int64
            let chatID: UUID
            let senderID: UUID
            let createdAt: Date
            let content: ReactionContent
            
            enum CodingKeys: String, CodingKey {
                case updateID = "update_id"
                case chatID = "chat_id"
                case senderID = "sender_id"
                case createdAt = "created_at"
                case content = "content"
            }
        }
        
        struct ReactionContent: Codable {
            let reaction: String
            let messageID: UUID
            
            enum CodingKeys: String, CodingKey {
                case reaction = "reaction"
                case messageID = "message_id"
            }
        }
    }
    
    enum PersonalChat {
        struct CreateRequest: Codable {
            let memberID: UUID
            
            enum CodingKeys: String, CodingKey {
                case memberID = "member_id"
            }
        }
        
        struct Response: Codable {
            let chatID: UUID
            let members: [UUID]
            let blocked: Bool
            let blockedBy: [UUID]?
            let createdAt: Date
            
            enum CodingKeys: String, CodingKey {
                case chatID = "chat_id"
                case members = "members"
                case blocked = "blocked"
                case blockedBy = "blocked_by"
                case createdAt = "created_at"
            }
        }
    }
    
    enum SecretPersonalChat {
        struct ExpirationRequest: Codable {
            let expiration: String?
        }
        
        struct Response: Codable {
            let chatID: UUID
            let memberID: UUID
            let expiration: String?
            
            enum CodingKeys: String, CodingKey {
                case chatID = "chat_id"
                case memberID = "member_id"
                case expiration = "expiration"
            }
        }
    }
    
    enum GroupChat {
        struct CreateRequest: Codable {
            let name: String
            let description: String?
            let members: [UUID]
        }
        
        struct UpdateRequest: Codable {
            let name: String
            let description: String?
        }
        
        struct PhotoUpdateRequest: Codable {
            let photoID: UUID
            enum CodingKeys: String, CodingKey {
                case photoID = "photo_id"
            }
        }
        
        struct Response: Codable {
            let id: UUID
            let name: String
            let description: String?
            let members: [UUID]
            let createdAt: String
            let adminID: UUID
            let groupPhoto: URL?
            
            enum CodingKeys: String, CodingKey {
                case id = "id"
                case name = "name"
                case description = "description"
                case members = "members"
                case createdAt = "created_at"
                case adminID = "admin_id"
                case groupPhoto = "group_photo"
            }
        }
    }
    
    enum SecretGroupChat {
        struct Response: Codable {
            let id: UUID
            let name: String
            let description: String?
            let members: [UUID]
            let createdAt: String
            let adminID: UUID
            let groupPhoto: URL?
            let expiration: String
            
            enum CodingKeys: String, CodingKey {
                case id = "id"
                case name = "name"
                case description = "description"
                case members = "members"
                case createdAt = "created_ad"
                case adminID = "admin_id"
                case groupPhoto = "group_photo"
                case expiration = "expiration"
            }
        }
    }
    
    enum UpdateModels {
        struct SendMessageRequest: Codable {
            let text: String
            let replyTo: UUID?
            
            enum CodingKeys: String, CodingKey {
                case text = "text"
                case replyTo = "reply_to"
            }
        }
        
        struct EditMessageRequest: Codable {
            let text: String
            enum CodingKeys: String, CodingKey {
                case text = "text"
            }
        }
        
        
        struct FileMessageRequest: Codable {
            let fileID: UUID
            let replyTo: Int64?
            
            enum CodingKeys: String, CodingKey {
                case fileID = "file_id"
                case replyTo = "reply_to"
            }
        }
        
        struct ReactionRequest: Codable {
            let reaction: String
            let messageID: Int64
            
            enum CodingKeys: String, CodingKey {
                case reaction = "reaction"
                case messageID = "message_id"
            }
        }
        
        struct ForwardMessageRequest: Codable {
            let messages: [Int64]
            let fromChatID: UUID
            
            enum CodingKeys: String, CodingKey {
                case messages = "messages"
                case fromChatID = "from_chat_id"
            }
        }
    }
    
    enum SecretUpdateModels {
        struct SendMessageRequest: Codable {
            let payload: String
            let initializationVector: String
            let keyID: UUID
            
            enum CodingKeys: String, CodingKey {
                case payload = "payload"
                case initializationVector = "initialization_vector"
                case keyID = "key_id"
            }
        }
        
        struct SecretPreview: Codable {
            let updateID: Int64
            let chatID: UUID
            let senderID: UUID
            let createdAt: String
            let content: SendMessageRequest
            
            enum CodingKeys: String, CodingKey {
                case updateID = "update_id"
                case chatID = "chat_id"
                case senderID = "sender_id"
                case createdAt = "created_at"
                case content = "content"
            }
        }
    }
}

enum DeleteMode: String, Codable {
    case DeleteModeForSender = "for_deletion_sender"
    case DeleteModeForAll = "for_all"
}

enum ChatType: String, Codable {
    case personal = "personal"
    case personalSecret = "personal_secret"
    case group = "group"
    case groupSecret = "group_secret"
}
