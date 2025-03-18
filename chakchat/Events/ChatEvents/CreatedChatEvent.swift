//
//  CreatedPersonalChatEvent.swift
//  chakchat
//
//  Created by Кирилл Исаев on 06.03.2025.
//

import Foundation

final class CreatedChatEvent: Event {
    
    let chatID: UUID
    let type: ChatType
    let members: [UUID]
    let createdAt: Date
    let info: ChatsModels.GeneralChatModel.Info
    
    init(chatID: UUID, type: ChatType, members: [UUID], createdAt: Date, info: ChatsModels.GeneralChatModel.Info) {
        self.chatID = chatID
        self.type = type
        self.members = members
        self.createdAt = createdAt
        self.info = info
    }
}
