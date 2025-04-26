//
//  UserProfileProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import Foundation

// MARK: - UserProfileProtocols
protocol UserProfileBusinessLogic {
    func routeToChat(_ isChatExisting: ChatsModels.GeneralChatModel.ChatData?)
    func searchForExistingChat()
    func createSecretChat()
    
    func setExpiration(_ time: String)
    
    func blockChat()
    func unblockChat()
    
    func deleteChat(_ deleteMode: DeleteMode)
    
    func switchNotification()
    func passUserData()
    func searchMessages()
    func routeBack()
    func routeToChatsScreen()
    
    func changeSecretKey(_ key: String)
}

protocol UserProfilePresentationLogic {
    func passUserData(
        _ isBlocked: Bool,
        _ userData: ProfileSettingsModels.ProfileUserData,
        _ profileConfiguration: ProfileConfiguration
    )
    func passBlocked()
    func passUnblocked()
    func updateBlockStatus(isBlock: Bool)
    func showFailDisclaimer()
    func showSecretChatExists(_ user: String)
}

protocol UserProfileWorkerLogic {
    func searchMessages()
    func switchNotification()
    func createSecretChat(_ memberID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void)
    
    func setExpiration(_ time: String)
    
    func blockChat(_ chatID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void)
    func unblockChat(_ chatID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void)
    
    func deleteChat(_ chatID: UUID, _ deleteMode: DeleteMode, _ chatType: ChatType, completion: @escaping (Result<EmptyResponse, Error>) -> Void)
    
    func searchForExistingChat(_ memberID: UUID) -> Chat?
    func getMyID() -> UUID
    
    func changeSecretKey(_ key: String, _ chatID: UUID) -> Bool
}
