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
    /// update methods
    /// using completions to incicate, what kind of response server sent(true=200, false = else)
    func deleteMessage(_ updateID: Int64, _ deleteMode: DeleteMode, completion: @escaping (Bool) -> Void)
    func editTextMessage(_ updateID: Int64, _ text: String, completion: @escaping (Bool) -> Void)
    func sendFileMessage(_ fileID: UUID, _ replyTo: Int64?, completion: @escaping (Bool) -> Void)
    func sendReaction(_ reaction: String, _ messageID: Int64, completion: @escaping (Bool) -> Void)
    func deleteReaction(_ updateID: Int64, completion: @escaping (Bool) -> Void)
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
    
    func deleteMessage(_ chatID: UUID, _ updateID: Int64, _ deleteMode: DeleteMode, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func editTextMessage(_ chatID: UUID, _ updateID: Int64, _ text: String, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func sendFileMessage(_ chatID: UUID, _ fileID: UUID, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func sendReaction(_ chatID: UUID, _ reaction: String, _ messageID: Int64, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func deleteReaction(_ chatID: UUID, _ updateID: Int64, completion: @escaping (Result<UpdateData, Error>) -> Void)
}

protocol SendingMessagesProtocol: AnyObject {
    func sendTextMessage(_ message: String, completion: @escaping (Bool) -> Void)
}
