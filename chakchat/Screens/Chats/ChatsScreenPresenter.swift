//
//  ChatsScreenPresenter.swift
//  chakchat
//
//  Created by Кирилл Исаев on 21.01.2025.
//

import Foundation

// MARK: - ChatsScreenPresenter
final class ChatsScreenPresenter: ChatsScreenPresentationLogic {

    weak var view: ChatsScreenViewController?
    
    func showChats(_ chats: ChatsModels.GeneralChatModel.ChatsData) {
        view?.showChats(chats)
    }
    
    func addNewChat(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        view?.addNewChat(chatData)
    }
    
    func addMember(_ event: AddedMemberEvent) {
        view?.addMember(event)
    }
    
    func removeMember(_ event: DeletedMemberEvent) {
        view?.removeMember(event)
    }
    
    func deleteChat(_ chatID: UUID) {
        view?.deleteChat(chatID)
    }
    
    func updateGroupInfo(_ event: UpdatedGroupInfoEvent) {
        view?.updateGroupInfo(event)
    }
    
    func updateGroupPhoto(_ event: UpdatedGroupPhotoEvent) {
        view?.updateGroupPhoto(event)
    }
    
    func changeChatPreview(_ event: WSUpdateEvent) {
        if event.updateData.type == .textMessage || event.updateData.type == .file {
            view?.changeChatPreview(event)
        }
    }
    
    func showNewChat(_ event: WSChatCreatedEvent) {
        let chatData = ChatsModels.GeneralChatModel.ChatData(
            chatID: event.chatCreatedData.chat.chatID,
            type: event.chatCreatedData.chat.type,
            members: event.chatCreatedData.chat.members,
            createdAt: event.chatCreatedData.chat.createdAt,
            info: event.chatCreatedData.chat.info,
            updatePreview: nil
        )
        view?.addNewChat(chatData)
    }
    
    func changeGroupInfo(_ event: WSGroupInfoUpdatedEvent) {
        view?.changeGroupInfo(event)
    }
    
    func addMember(_ event: WSGroupMembersAddedEvent) {
        view?.addMember(event)
    }
    
    func removeMember(_ event: WSGroupMembersRemovedEvent) {
        view?.removeMember(event)
    }
}
