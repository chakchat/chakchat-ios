//
//  MessagesModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 04.04.2025.
//

import Foundation

struct Message: Codable {
    let type: MessageType
    let data: MessageData
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
    let updateID: Int64
    let type: UpdateDataType
    let senderID: UUID
    let createdAt: Date
    let content: UpdateContent
    
    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case updateID = "update_id"
        case type
        case senderID = "sender_id"
        case createdAt = "created_at"
        case content
    }
}

struct ChatCreatedData: Codable {
    let senderID: UUID
    let chat: ChatData
    
    enum CodingKeys: String, CodingKey {
        case senderID = "sender_id"
        case chat
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
        case type
        case members
        case createdAt = "created_at"
        case info
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
        case expiration
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
        case name
        case description
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
        case members
    }
}


indirect enum UpdateContent: Codable {
    case textContent(TextContent)
    case fileContent(FileContent)
    case reactionContent(ReactionContent)
    case editedContent(EditedContent)
}

struct TextContent: Codable {
    let text: String
    let edited: UpdateData?
    let replyTo: UUID
    let reactions: [UpdateData]?
    
    enum CodingKeys: String, CodingKey {
        case text
        case edited
        case replyTo = "reply_to"
        case reactions
    }
}

struct FileContent: Codable {
    let fileID: UUID
    let fileName: String
    let mimeType: String
    let fileSize: Int64
    let fileURL: URL
    let messageID: Int64
}

struct ReactionContent: Codable {
    let reaction: String
    let messageID: Int64
}

struct EditedContent: Codable {
    let newText: String
    let messageID: UUID
    
    enum CodingKeys: String, CodingKey {
        case newText = "new_text"
        case messageID = "message_id"
    }
}

enum MessageType: String, Codable {
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
    case file = "file"
    case reaction = "reaction"
}
