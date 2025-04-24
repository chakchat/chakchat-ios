//
//  ChatsScreenProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 21.01.2025.
//

import UIKit

// MARK: - ChatsScreen Protocols
protocol ChatsScreenBusinessLogic: SearchInteractor {
    func loadMeData()
    func loadMeRestrictions()
    func loadChats()
    
    func searchForExistingChat(_ userData: ProfileSettingsModels.ProfileUserData)
    
    func showChats(_ allChatsData: ChatsModels.GeneralChatModel.ChatsData)
    func addNewChat(_ chatData: ChatsModels.GeneralChatModel.ChatData)
    func deleteChat(_ chatID: UUID)
    
    func routeToSettingsScreen()
    func routeToNewMessageScreen()
    func routeToChat(_ chatData: ChatsModels.GeneralChatModel.ChatData)

    func getChatInfo(
        _ chat: ChatsModels.GeneralChatModel.ChatData,
        completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatInfo, Error>) -> Void
    )
}

protocol ChatsScreenPresentationLogic {
    func showChats(_ allChatsData: ChatsModels.GeneralChatModel.ChatsData)
    func addNewChat(_ chatData: ChatsModels.GeneralChatModel.ChatData)
    func deleteChat(_ chatID: UUID)
}

protocol ChatsScreenWorkerLogic {
    func loadMeData(completion: @escaping (Result<Void, Error>) -> Void)
    func loadMeRestrictions(completion: @escaping (Result<Void, Error>) -> Void)
    func loadChats(completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatsData, Error>) -> Void)
    
    func fetchUsers(
        _ name: String?,
        _ username: String?,
        _ page: Int,
        _ limit: Int,
        completion: @escaping (Result<ProfileSettingsModels.Users, Error>) -> Void
    )
    
    func getUserDataByID(_ users: [UUID], completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, Error>) -> Void)
    func getDBChats() -> [ChatsModels.GeneralChatModel.ChatData]?
    
    func refreshChats(_ chats: ChatsModels.GeneralChatModel.ChatsData)
    
    func searchForExistingChat(_ memberID: UUID) -> Chat?
}

// MARK: - SearchInteractor Protocol
protocol SearchInteractor {
    func fetchUsers(_ name: String?, _ username: String?, _ page: Int, _ limit: Int, completion: @escaping (Result<ProfileSettingsModels.Users, Error>) -> Void)
    
    func handleError(_ error: Error)
}
