//
//  MessagesModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 04.04.2025.
//

import Foundation

struct Message: Codable {
    let type: WSMessageType
    let data: MessageData
}

struct Updates: Codable {
    let updates: [UpdateData]
}

enum MessageData: Codable {
    case update(UpdateData)
    case chatCreated(ChatCreatedData)
    case delete(DeleteChatData)
    case expiration(ChatExpirationSetData)
    case updateGroupInfo(UpdateGroupInfoData)
    case updateGroupMembers(UpdateGroupMembersData)
}

struct UpdateData: Codable {
    let chatID: UUID
    let content: UpdateContent
    let createdAt: Date
    let senderID: UUID
    let type: UpdateDataType
    let updateID: Int64
    
    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case updateID = "update_id"
        case type = "type"
        case senderID = "sender_id"
        case createdAt = "created_at"
        case content = "content"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        chatID = try container.decode(UUID.self, forKey: .chatID)
        senderID = try container.decode(UUID.self, forKey: .senderID)
        updateID = try container.decode(Int64.self, forKey: .updateID)
        type = try container.decode(UpdateDataType.self, forKey: .type)
        
        let timestamp = try container.decode(Double.self, forKey: .createdAt)
        createdAt = Date(timeIntervalSince1970: timestamp)
        
        switch type {
        case .textMessage:
            let textContent = try container.decode(TextContent.self, forKey: .content)
            content = .textContent(textContent)
        case .file:
            let fileContent = try container.decode(FileContent.self, forKey: .content)
            content = .fileContent(fileContent)
        case .reaction:
            let reactionContent = try container.decode(ReactionContent.self, forKey: .content)
            content = .reactionContent(reactionContent)
        case .textEdited:
            let editedContent = try container.decode(EditedContent.self, forKey: .content)
            content = .editedContent(editedContent)
        case .delete:
            let deletedContent = try container.decode(DeletedContent.self, forKey: .content)
            content = .deletedContent(deletedContent)
        }
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(chatID, forKey: .chatID)
        try container.encode(senderID, forKey: .senderID)
        try container.encode(updateID, forKey: .updateID)
        try container.encode(type, forKey: .type)
        try container.encode(createdAt.timeIntervalSince1970, forKey: .createdAt)
        
        switch content {
        case .textContent(let text):
            try container.encode(text, forKey: .content)
        case .fileContent(let file):
            try container.encode(file, forKey: .content)
        case .reactionContent(let reaction):
            try container.encode(reaction, forKey: .content)
        case .editedContent(let edited):
            try container.encode(edited, forKey: .content)
        case .deletedContent(let deleted):
            try container.encode(deleted, forKey: .content)
        }
    }
}

struct ChatCreatedData: Codable {
    let senderID: UUID
    let chat: ChatData
    
    enum CodingKeys: String, CodingKey {
        case senderID = "sender_id"
        case chat = "chat"
    }
}

struct ChatData: Codable {
    let chatID: UUID
    let type: ChatType
    let members: [UUID]
    let createdAt: Date
    let info: ChatsModels.GeneralChatModel.Info
    
    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case type = "type"
        case members = "members"
        case createdAt = "created_at"
        case info = "info"
    }
}

struct DeleteChatData: Codable {
    let senderID: UUID
    let chatID: UUID
    
    enum CodingKeys: String, CodingKey {
        case senderID = "sender_id"
        case chatID = "chat_id"
    }
}

struct ChatExpirationSetData: Codable {
    let senderID: UUID
    let chatID: UUID
    let expiration: String?
    
    enum CodingKeys: String, CodingKey {
        case senderID = "sender_id"
        case chatID = "chat_id"
        case expiration = "expiration"
    }
}

struct UpdateGroupInfoData: Codable {
    let senderID: UUID
    let chatID: UUID
    let name: String
    let description: String?
    let groupPhoto: URL?
    
    enum CodingKeys: String, CodingKey {
        case senderID = "sender_id"
        case chatID = "chat_id"
        case name = "name"
        case description = "description"
        case groupPhoto = "group_photo"
    }
}

struct UpdateGroupMembersData: Codable {
    let senderID: UUID
    let chatID: UUID
    let members: [UUID]
    
    enum CodingKeys: String, CodingKey {
        case senderID = "sender_id"
        case chatID = "chat_id"
        case members = "members"
    }
}


enum UpdateContent: Codable {
    case textContent(TextContent)
    case fileContent(FileContent)
    case reactionContent(ReactionContent)
    case editedContent(EditedContent)
    case deletedContent(DeletedContent)
}

struct TextContent: Codable {
    let replyTo: Int64?
    let text: String
    let forwarded: Bool?
    let edited: EditedInfo?
    let reactions: [ReactionInfo]?
    
    enum CodingKeys: String, CodingKey {
        case text = "text"
        case edited = "edited"
        case replyTo = "reply_to"
        case reactions = "reactions"
        case forwarded = "forwarded"
    }
}

struct EditedInfo: Codable {
    let chatID: UUID
    let updateID: Int64
    let type: UpdateDataType
    let senderID: UUID
    let createdAt: Date
    let content: EditedContent
    
    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case updateID = "update_id"
        case type = "type"
        case senderID = "sender_id"
        case createdAt = "created_at"
        case content = "content"
    }
}

struct EditedContent: Codable {
    let newText: String
    let messageID: Int64
    
    enum CodingKeys: String, CodingKey {
        case newText = "new_text"
        case messageID = "message_id"
    }
}

struct FileContent: Codable {
    let file: FileInfo
    let replyTo: Int64?
    let forwarded: Bool?
    let reactions: [ReactionInfo]?
    
    enum CodingKeys: String, CodingKey {
        case file = "file"
        case replyTo = "reply_to"
        case reactions = "reactions"
        case forwarded = "forwarded"
    }
}

struct FileInfo: Codable {
    let fileID: UUID
    let fileName: String
    let mimeType: String
    let fileSize: Int64
    let fileURL: URL
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case fileID = "file_id"
        case fileName = "file_name"
        case mimeType = "mime_type"
        case fileSize = "file_size"
        case fileURL = "file_url"
        case createdAt = "created_at"
    }
}

struct ReactionInfo: Codable {
    let chatID: UUID
    let updateID: Int64
    let type: UpdateDataType
    let senderID: UUID
    let createdAt: Date
    let content: ReactionContent
    
    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case updateID = "update_id"
        case type = "type"
        case senderID = "sender_id"
        case createdAt = "created_at"
        case content = "content"
    }
}

struct ReactionContent: Codable {
    let reaction: String
    let messageID: Int64
    
    enum CodingKeys: String, CodingKey {
        case reaction = "reaction"
        case messageID = "message_id"
    }
}

struct DeletedContent: Codable {
    let deletedID: Int64
    let deletedMode: DeleteMode
    
    enum CodingKeys: String, CodingKey {
        case deletedID = "deleted_id"
        case deletedMode = "deleted_mode"
    }
}

enum WSMessageType: String, Codable {
    case update = "update"
    case chatCreated = "chat_created"
    case chatDeleted = "chat_deleted"
    case chatBlocked = "chat_blocked"
    case chatUnblocked = "chat_unblocked"
    case chatExpirationSet = "chat_expiration_set"
    case groupInfoUpdated = "group_info_update"
    case groupMembersAdded = "group_members_added"
    case groupMembersRemoved = "group_members_removed"
}

enum UpdateDataType: String, Codable {
    case textMessage = "text_message"
    case textEdited = "text_message_edited"
    case file = "file_message"
    case reaction = "reaction"
    case delete = "update_deleted"
}
