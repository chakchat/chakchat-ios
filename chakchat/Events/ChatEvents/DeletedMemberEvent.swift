//
//  DeletedMemberEvent.swift
//  chakchat
//
//  Created by Кирилл Исаев on 12.03.2025.
//

import Foundation

class DeletedMemberEvent: Event {
    let memberID: UUID
    let chatID: UUID
    
    init(memberID: UUID, chatID: UUID) {
        self.memberID = memberID
        self.chatID = chatID
    }
}
