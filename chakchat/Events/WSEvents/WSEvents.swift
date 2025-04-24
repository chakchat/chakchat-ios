//
//  NewUpdateEvent.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.04.2025.
//

import Foundation

final class WSUpdateEvent: Event {
    
    let updateData: UpdateData
    
    init(updateData: UpdateData) {
        self.updateData = updateData
    }
}

final class WSChatCreatedEvent: Event {
    
    let chatCreatedData: ChatCreatedData
    
    init(chatCreadetData: ChatCreatedData) {
        self.chatCreatedData = chatCreadetData
    }
}

final class WSChatDeletedEvent: Event {
    
    let chatDeletedData: DeleteChatData
    
    init(chatDeletedData: DeleteChatData) {
        self.chatDeletedData = chatDeletedData
    }
}

final class WSChatBlockedEvent: Event {
    
    let chatBlockedData: DeleteChatData
    
    init(chatBlockedData: DeleteChatData) {
        self.chatBlockedData = chatBlockedData
    }
}

final class WSChatUnblockedEvent: Event {
    
    let chatUnblockedData: DeleteChatData
    
    init(chatUnblockedData: DeleteChatData) {
        self.chatUnblockedData = chatUnblockedData
    }
}

final class WSChatExpirationSetEvent: Event {
    
    let chatExpirationSetData: ChatExpirationSetData
    
    init(chatExpirationSetData: ChatExpirationSetData) {
        self.chatExpirationSetData = chatExpirationSetData
    }
}

final class WSGroupInfoUpdatedEvent: Event {
    
    let groupInfoUpdatedData: UpdateGroupInfoData
    
    init(groupInfoUpdatedData: UpdateGroupInfoData) {
        self.groupInfoUpdatedData = groupInfoUpdatedData
    }
}

final class WSGroupMembersAddedEvent: Event {
    
    let groupMembersAddedData: UpdateGroupMembersData
    
    init(groupMembersAddedData: UpdateGroupMembersData) {
        self.groupMembersAddedData = groupMembersAddedData
    }
}

final class WSGroupMembersRemovedEvent: Event {
    
    let groupMembersRemovedData: UpdateGroupMembersData
    
    init(groupMembersRemovedData: UpdateGroupMembersData) {
        self.groupMembersRemovedData = groupMembersRemovedData
    }
}
