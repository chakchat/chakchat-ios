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
}
