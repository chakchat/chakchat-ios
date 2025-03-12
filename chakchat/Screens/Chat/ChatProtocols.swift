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
    func createChat(_ memberID: UUID)
    func passUserData()
    func setExpirationTime(_ expiration: String?)
}

protocol ChatPresentationLogic {
    func passUserData(_ userData: ProfileSettingsModels.ProfileUserData, _ isSecret: Bool)
}

protocol ChatWorkerLogic {
    func createChat(_ memberID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void)
    func setExpirationTime(
        _ chatID: UUID,
        _ expiration: String?,
        completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void
    )
    func sendTextMessage(_ message: String)
}

protocol SendingMessagesProtocol: AnyObject {
    func sendTextMessage(_ message: String)
}
