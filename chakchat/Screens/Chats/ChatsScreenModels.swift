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
            var name: String
            var description: String?
            var groupPhoto: URL?
            
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
                case admin = "admin_id"
                case name = "name"
                case description = "description"
                case groupPhoto = "group_photo"
                case expiration = "expiration"
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                admin = try container.decode(UUID.self, forKey: .admin)
                name = try container.decode(String.self, forKey: .name)
                description = try container.decodeIfPresent(String.self, forKey: .description)
                expiration = try container.decodeIfPresent(String.self, forKey: .expiration)
                if let groupPhotoString = try container.decodeIfPresent(String.self, forKey: .groupPhoto), !groupPhotoString.isEmpty {
                    groupPhoto = URL(string: groupPhotoString)
                } else {
                    groupPhoto = nil
                }
            }
        }
        
        struct ChatData: Codable {
            let chatID: UUID
            let type: ChatType
            var members: [UUID]
            let createdAt: Date
            var info: Info
            let updatePreview: [Preview]?
            
            enum CodingKeys: String, CodingKey {
                case chatID = "chat_id"
                case type = "type"
                case members = "members"
                case createdAt = "created_at"
                case info = "info"
                case updatePreview = "update_preview"
            }
            
            init(chatID: UUID, type: ChatType, members: [UUID], createdAt: Date, info: Info, updatePreview: [Preview]?) {
                self.chatID = chatID
                self.type = type
                self.members = members
                self.createdAt = createdAt
                self.info = info
                self.updatePreview = updatePreview
            }
            
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                chatID = try container.decode(UUID.self, forKey: .chatID)
                type = try container.decode(ChatType.self, forKey: .type)
                members = try container.decode([UUID].self, forKey: .members)
                createdAt = try container.decode(Date.self, forKey: .createdAt)
                updatePreview = try container.decodeIfPresent([Preview].self, forKey: .updatePreview)
                
                switch type {
                case .personal:
                    let personalInfo = try container.decode(PersonalInfo.self, forKey: .info)
                    info = .personal(personalInfo)
                case .secretPersonal:
                    let personalSecretInfo = try container.decode(SecretPersonalInfo.self, forKey: .info)
                    info = .secretPersonal(personalSecretInfo)
                case .group:
                    let groupInfo = try container.decode(GroupInfo.self, forKey: .info)
                    info = .group(groupInfo)
                case .secretGroup:
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
                try container.encodeIfPresent(updatePreview, forKey: .updatePreview)
                
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
            let content: UpdateContent
            
            enum CodingKeys: String, CodingKey {
                case updateID = "update_id"
                case type = "type"
                case chatID = "chat_id"
                case senderID = "sender_id"
                case createdAt = "created_at"
                case content = "content"
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                updateID = try container.decode(Int64.self, forKey: .updateID)
                type = try container.decode(UpdateDataType.self, forKey: .type)
                chatID = try container.decode(UUID.self, forKey: .chatID)
                senderID = try container.decode(UUID.self, forKey: .senderID)
                createdAt = try container.decode(Date.self, forKey: .createdAt)

                switch type {
                case .textMessage:
                    let value = try container.decode(TextContent.self, forKey: .content)
                    content = .textContent(value)
                case .file:
                    let value = try container.decode(FileContent.self, forKey: .content)
                    content = .fileContent(value)
                case .reaction:
                    let value = try container.decode(ReactionContent.self, forKey: .content)
                    content = .reactionContent(value)
                case .textEdited:
                    let value = try container.decode(EditedContent.self, forKey: .content)
                    content = .editedContent(value)
                case .delete:
                    let value = try container.decode(DeletedContent.self, forKey: .content)
                    content = .deletedContent(value)
                case .secret:
                    let value = try container.decode(SecretContent.self, forKey: .content)
                    content = .secretContent(value)
                }
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
            let replyTo: Int64?
            
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
            let message: Int64
            let fromChatID: UUID
            
            enum CodingKeys: String, CodingKey {
                case message = "message"
                case fromChatID = "from_chat_id"
            }
        }
    }
    
    enum SecretUpdateModels {
        struct SendMessageRequest: Codable {
            let payload: Data
            let initializationVector: Data
            let keyHash: Data
            
            enum CodingKeys: String, CodingKey {
                case payload = "payload"
                case initializationVector = "initialization_vector"
                case keyHash = "key_hash"
            }
        }
        
        struct SecretPreview: Codable {
            let updateID: Int64
            let chatID: UUID
            let senderID: UUID
            let createdAt: Date
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
    case secretPersonal = "secret_personal"
    case group = "group"
    case secretGroup = "secret_group"
}
