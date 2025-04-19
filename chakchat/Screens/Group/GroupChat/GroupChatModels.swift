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

protocol GroupMessageStatusProtocol {
    var status: MessageStatus { get set }
}

protocol GroupMessageForwardedStatus {
    var isForwarded: Bool { get set }
}

struct GroupSender: SenderType {
    var senderId: String
    var displayName: String
    var avatar: UIImage?
}

struct GroupTextMessage: MessageType, GroupMessageStatusProtocol, GroupMessageForwardedStatus {
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
    var curUserPickedReaction: String?
    
    var status: MessageStatus
    var isForwarded: Bool
    
    init() {
        sender = GroupSender(senderId: "", displayName: "")
        messageId = ""
        sentDate = Date()
        kind = .text("")
        text = ""
        replyTo = nil
        replyToID = nil
        isEdited = true
        editedMessage = nil
        reactions = nil
        status = .sending
        isForwarded = false
    }
}

struct GroupTextMessageEdited: MessageType, GroupMessageStatusProtocol {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    var newText: String
    var oldTextUpdateID: Int64
    
    var status: MessageStatus
    
    init() {
        sender = GroupSender(senderId: "", displayName: "")
        messageId = ""
        sentDate = Date()
        kind = .text("")
        newText = ""
        oldTextUpdateID = 0
        status = .sending
    }
}

struct GroupFileMessage: MessageType, GroupMessageStatusProtocol, GroupMessageForwardedStatus {
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
    
    var status: MessageStatus
    var isForwarded: Bool
    
    init() {
        sender = GroupSender(senderId: "", displayName: "")
        messageId = ""
        sentDate = Date()
        kind = .text("")
        fileID = UUID()
        fileName = ""
        mimeType = ""
        fileSize = 0
        fileURL = URL(filePath: "")
        reactions = nil
        status = .sending
        isForwarded = false
    }
    
}

struct GroupReaction: MessageType, GroupMessageStatusProtocol {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    var onMessageID: Int64
    var reaction: String
    
    var status: MessageStatus
}

struct GroupMessageDelete: MessageType, GroupMessageStatusProtocol {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    var deletedMessageID: Int64
    var deleteMode: DeleteMode
    
    var status: MessageStatus
    
    init() {
        sender = GroupSender(senderId: "", displayName: "")
        messageId = ""
        sentDate = Date()
        kind = .text("")
        deletedMessageID = 1
        deleteMode = .DeleteModeForAll
        status = .sending
    }
}

struct GroupOutgoingMessage: MessageType, GroupMessageStatusProtocol {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    var replyTo: MessageType?
    
    var status: MessageStatus
}

struct PhotoMediaItem: MediaItem, GroupMessageStatusProtocol {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var shimmer: UIView?
    var size: CGSize
    
    var status: MessageStatus
}

struct VideoMediaItem: MediaItem, GroupMessageStatusProtocol {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    var status: MessageStatus
}

struct FileItem: GroupMessageStatusProtocol {
    var url: URL
    var status: MessageStatus
}

struct FileObject {
    var url: URL
    var data: Data
}

struct OutgoingPhotoMessage: MessageType, GroupMessageStatusProtocol {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind {
        return .photo(media)
    }
    let media: MockMediaItem
    var status: MessageStatus
}

struct OutgoingFileMessage: MessageType, GroupMessageStatusProtocol {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var status: MessageStatus
}

struct MockMediaItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

enum ForwardType {
    case text
    case file
}
