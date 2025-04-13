//
//  ChatModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.04.2025.
//

import UIKit
import MessageKit
import DifferenceKit

protocol MessageStatusProtocol {
    var sender: SenderType { get }
    var sentDate: Date { get }
    var isEdited: Bool { get }
    var status: MessageStatus { get }
}

struct SenderPerson: SenderType {
    let senderId: String
    let displayName: String
}

struct MessageForKit: MessageType, MessageStatusProtocol {
    let sender: SenderType
    let messageId: String
    let sentDate: Date
    let kind: MessageKind
    var status: MessageStatus
    var isEdited: Bool
    
    let chatID: UUID
    let updateID: Int64
    let contentType: MessageContentType
    let content: ChatMessageContent
}

enum ChatMessageContent {
    case text(ChatTextContent)
    case file(ChatFileContent)
    case reaction(ChatReactionContent)
    case textEdited(ChatTextEditedContent)
    case deleted(ChatDeletedUpdateContent)
}

struct ChatTextContent {
    let text: String
    var edited: ChatTextEditedContent?
    var replyTo: Int64?
    var reactions: [ChatReactionContent]?
}

struct ChatFileContent {
    let fileID: UUID
    let fileName: String
    let mimeType: String
    let fileSize: Int64
    let fileURL: URL
    let createdAt: Date
}

struct ChatReactionContent {
    let reaction: String
    let messageID: Int64
}

struct ChatTextEditedContent {
    let newText: String
    let messageID: Int64
}

struct ChatDeletedUpdateContent {
    let deletedID: Int64
    let deleteMode: DeleteMode
}

enum MessageContentType: String {
    case text = "text"
    case file = "file"
    case reaction = "reaction"
    case deleted = "deleted"
    case textEdited = "textEdited"
}
extension MessageKind: Equatable {
    public static func == (lhs: MessageKind, rhs: MessageKind) -> Bool {
        switch (lhs, rhs) {
        case (.text(let lhsText), .text(let rhsText)):
            return lhsText == rhsText
        case (.attributedText(let lhsAttr), .attributedText(let rhsAttr)):
            return lhsAttr.string == rhsAttr.string
        case (.photo(let lhsMedia), .photo(let rhsMedia)):
            return lhsMedia.url == rhsMedia.url
        case (.video(let lhsMedia), .video(let rhsMedia)):
            return lhsMedia.url == rhsMedia.url
        default:
            return false
        }
    }
}

extension MessageForKit: Differentiable {
    var differenceIdentifier: String {
        return messageId
    }
    
    func isContentEqual(to source: MessageForKit) -> Bool {
        return self.kind == source.kind &&
               self.sender.senderId == source.sender.senderId &&
               self.sentDate == source.sentDate
    }
}

struct PhotoMessage: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind {
        return .photo(media)
    }
    let media: ImageMediaItem
}

struct ImageMediaItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: image.size.width, height: image.size.height)
        self.placeholderImage = UIImage()
    }
}

struct OutgoingMessage: MessageType, MessageStatusProtocol {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var isEdited: Bool
    var status: MessageStatus
    
    let text: String
    let replyTo: Int64?
}

struct DeleteKind {
    let deleteMessageID: Int64
    let deleteMode: DeleteMode
}

enum MessageStatus: String {
    case sending = "Sending"
    case sent = "✓"
    case read = "✓✓"
    case error = "!"
    case edited = "upd"
}
