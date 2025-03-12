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
        
        struct PersonalInfo: Codable {
            let blockedBy: [UUID]?
            
            enum CodingKeys: String, CodingKey {
                case blockedBy = "blocked_by"
            }
        }

        struct GroupInfo: Codable {
            let admin: UUID
            let name: String
            let description: String?
            let groupPhoto: URL?
            
            enum CodingKeys: String, CodingKey {
                case admin = "admin"
                case name = "name"
                case description = "description"
                case groupPhoto = "group_photo"
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
            let members: [UUID]
            let createdAt: Date
            let info: Info
            
            enum CodingKeys: String, CodingKey {
                case chatID = "chat_id"
                case type = "type"
                case members = "members"
                case createdAt = "created_at"
                case info = "info"
            }
        }
        
        enum Info: Codable {
            case personal(PersonalInfo)
            case group(GroupInfo)
            case secretPersonal(SecretPersonalInfo)
            case secretGroup(SecretGroupInfo)
            
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let info = try? container.decode(PersonalInfo.self) {
                    self = .personal(info)
                } else if let info = try? container.decode(GroupInfo.self) {
                    self = .group(info)
                } else if let info = try? container.decode(SecretPersonalInfo.self) {
                    self = .secretPersonal(info)
                } else if let info = try? container.decode(SecretGroupInfo.self) {
                    self = .secretGroup(info)
                } else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown ChatInfo type")
                }
            }
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .personal(let info):
                    try container.encode(info)
                case .group(let info):
                    try container.encode(info)
                case .secretPersonal(let info):
                    try container.encode(info)
                case .secretGroup(let info):
                    try container.encode(info)
                }
            }
        }
        
        struct Preview: Codable {
            let updateID: Int64
            let chatID: UUID
            let senderID: UUID
            let createdAt: Date
            let content: Content?
            
            enum CodingKeys: String, CodingKey {
                case updateID = "update_id"
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
            let replyTo: UUID
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
            let replyTo: UUID
            
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
            let replyTo: UUID
            
            enum CodingKeys: String, CodingKey {
                case fileID = "file_id"
                case replyTo = "reply_to"
            }
        }
        
        struct ReactionRequest: Codable {
            let reaction: String
            let messageID: UUID
            
            enum CodingKeys: String, CodingKey {
                case reaction = "reaction"
                case messageID = "message_id"
            }
        }
        
        struct ForwardMessageRequest: Codable {
            let messages: [UUID]
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

enum DeleteMode: String {
    case onlyMe = "only_me"
    case all = "all"
}

enum ChatType: String, Codable {
    case personal = "personal"
    case personalSecret = "personal_secret"
    case group = "group"
    case groupSecret = "group_secret"
}
