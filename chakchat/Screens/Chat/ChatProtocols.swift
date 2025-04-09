//
//  ChatProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import Foundation

// MARK: - ChatBusinessLogic
protocol ChatBusinessLogic: SendingMessagesProtocol {
    func routeBack()
    func routeToProfile()
    func createChat(_ memberID: UUID, completion: @escaping () -> Void)
    func passUserData()
    func setExpirationTime(_ expiration: String?)
    func handleChatBlock(_ event: BlockedChatEvent)
    func saveSecretKey(_ key: String)
}

protocol ChatPresentationLogic {
    func passUserData(_ userData: ProfileSettingsModels.ProfileUserData, _ isSecret: Bool)
    func showSecretKeyFail()
    
    func presentMessage(_ message: ChatModels.Message)
    func updateMessageStatus(_ id: String, _ newMessage: ChatModels.Message)
    func updateMessageStatus(_ id: String)
}

protocol ChatWorkerLogic {
    func createChat(_ memberID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void)
    func setExpirationTime(
        _ chatID: UUID,
        _ expiration: String?,
        completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void
    )
    func sendTextMessage(_ chatID: UUID, _ message: String, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func saveSecretKey(_ key: String) -> Bool
}

protocol SendingMessagesProtocol: AnyObject {
    func sendTextMessage(_ message: String, completion: @escaping (Bool) -> Void)
}
