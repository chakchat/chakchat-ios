//
//  ChatModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.04.2025.
//

import UIKit
import MessageKit
import DifferenceKit

enum ChatModels {
    struct Message: Hashable {
        let updateID: String
        let senderID: UUID
        let text: String
        let sentAt: Date
        var status: MessageStatus
    }
}

enum MessageStatus {
    case sending
    case sent
    case failed
}

// MessageKit
struct SenderPerson: SenderType {
    let senderId: String
    let displayName: String
}

struct MessageForKit: MessageType {
    let sender: SenderType
    let messageId: String
    let sentDate: Date
    let kind: MessageKind
    let updateType: UpdateDataType
    let deleteMode: DeleteMode?
    
    init(text: String, sender: SenderType, messageId: String, date: Date, updateType: UpdateDataType) {
        self.kind = .text(text)
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
        self.updateType = updateType
        self.deleteMode = nil
    }
    
    init(deleteText: String, sender: SenderType, deleteMessageId: String, date: Date, updateType: UpdateDataType, deleteMode: DeleteMode) {
        self.kind = .text(deleteText)
        self.sender = sender
        self.messageId = deleteMessageId
        self.sentDate = date
        self.updateType = updateType
        self.deleteMode = deleteMode
    }
    
    init(image: UIImage, sender: SenderType, messageId: String, date: Date, updateType: UpdateDataType) {
        let mediaItem = ImageMediaItem(image: image)
        self.kind = .photo(mediaItem)
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
        self.updateType = updateType
        self.deleteMode = nil
    }
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

struct ImageMediaItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }
}
