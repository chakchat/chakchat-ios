//
//  ChatModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.04.2025.
//

import UIKit
import MessageKit

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
    
    init(text: String, sender: SenderType, messageId: String, date: Date) {
        self.kind = .text(text)
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
    }
    
    init(image: UIImage, sender: SenderType, messageId: String, date: Date) {
        let mediaItem = ImageMediaItem(image: image)
        self.kind = .photo(mediaItem)
        self.sender = sender
        self.messageId = messageId
        self.sentDate = date
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
