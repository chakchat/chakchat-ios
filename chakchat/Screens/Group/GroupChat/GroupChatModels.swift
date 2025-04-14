//
//  GroupChatModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 14.04.2025.
//

import UIKit
import MessageKit

enum Kind {
    case GroupTextMessageKind
    case GroupTextMessageEditedKind
    case GroupFileMessageKind
    case GroupReactionKind
    case GroupMessageDeleteKind
}

struct GroupSender: SenderType {
    var senderId: String
    var displayName: String
    var avatar: UIImage?
}

struct GroupTextMessage: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    var text: String
    var replyTo: String?
    var replyToID: Int64?
    
    var isEdited: Bool
    var editedMessage: String?
    
    var reactions: [Int64: String]?
}

struct GroupTextMessageEdited: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    var newText: String
    var oldTextUpdateID: Int64
}

struct GroupFileMessage: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    var fileID: UUID
    var fileName: String
    var mimeType: String
    var fileSize: Int64
    var fileURL: URL
    
    var reactions: [Int64: String]?
    
}

struct GroupReaction: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    var onMessageID: Int64
    var reaction: String
}

struct GroupMessageDelete: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    var deletedMessageID: Int64
    var deleteMode: DeleteMode
}
