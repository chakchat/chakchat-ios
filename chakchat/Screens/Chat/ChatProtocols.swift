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
    func createChat(_ memberID: UUID)
    func passUserData()
}

protocol ChatPresentationLogic {
    func passUserData(_ userData: ProfileSettingsModels.ProfileUserData)
}

protocol ChatWorkerLogic {
    func createChat(_ memberID: UUID, completion: @escaping (Result<ChatsModels.PersonalChat.Response, Error>) -> Void)
    func sendTextMessage(_ message: String)
}

protocol SendingMessagesProtocol: AnyObject {
    func sendTextMessage(_ message: String)
}
