//
//  CoreDataManagerProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 28.02.2025.
//

import Foundation

protocol CoreDataManagerProtocol {
    
    func createChat(_ chatData: ChatsModels.GeneralChatModel.ChatData)
    func createChats(_ chatsData: ChatsModels.GeneralChatModel.ChatsData)
    func fetchChatByID(_ chatID: UUID) -> Chat?
    func fetchChatByMembers(_ myID: UUID, _ memberID: UUID, _ type: ChatType) -> Chat?
    func fetchChats() -> [Chat]
    func updateChat(_ chatData: ChatsModels.GeneralChatModel.ChatData)
    func deleteChat(_ chatID: UUID)
    func deleteAllChats()
    
    func refreshChats(_ chatsData: ChatsModels.GeneralChatModel.ChatsData)
    
    func createUser(_ userData: ProfileSettingsModels.ProfileUserData)
    func createUsers(_ usersData: ProfileSettingsModels.Users)
    func fetchUsers() -> [User]
    func fetchUserByID(_ userID: UUID) -> User?
    func updateUser(_ newUserData: ProfileSettingsModels.ProfileUserData)
    func deleteUser(_ user: User)
    func deleteAllUsers()
    
    @discardableResult
    func createTextMessageUpdate(_ updateData: UpdateData) -> TextUpdate
    @discardableResult
    func createTextEditedUpdate(_ updateData: UpdateData) -> EditUpdate?
    @discardableResult
    func createFileMessageUpdate(_ updateData: UpdateData) -> FileUpdate
    @discardableResult
    func createReactionUpdate(_ reactionInfo: ReactionInfo) -> ReactionUpdate
    @discardableResult
    func createDeletedUpdate(_ updateData: UpdateData) -> DeleteUpdate
    
    func fetchTextMessageUpdate(_ updateID: Int64) -> TextUpdate?
    func fetchTextEditedUpdate(_ updateID: Int64) -> EditUpdate?
    func fetchFileMessageUpdate(_ updateID: Int64) -> FileUpdate?
    func fetchReactionUpdate(_ updateID: Int64) -> ReactionUpdate?
    func fetchDeletedUpdate(_ updateID: Int64) -> DeleteUpdate?
    
    func updateTextMessageUpdate(_ updateData: UpdateData)
    func updateFileMessageUpdate(_ updateData: UpdateData)
    
    func deleteTextMessageUpdate(_ updateID: Int64)
    func deleteFileMessageUpdate(_ updateID: Int64)
}
