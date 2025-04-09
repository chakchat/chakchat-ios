//
//  ChatModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.04.2025.
//

import Foundation
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
    var status: MessageStatus
}
