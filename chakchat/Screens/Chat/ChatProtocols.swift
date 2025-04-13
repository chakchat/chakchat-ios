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
    ///  chatID временно для лонг пуллинга
    func loadFirstMessages(completion: @escaping (Result<[MessageForKit], Error>) -> Void)
    func loadMoreMessages()

    //func startPolling(completion: @escaping ([MessageForKit]) -> Void)
}

protocol ChatPresentationLogic {
    func passUserData(_ chatData: ChatsModels.GeneralChatModel.ChatData?, _ userData: ProfileSettingsModels.ProfileUserData, _ isSecret: Bool, _ myID: UUID)
    func showSecretKeyFail()
    
    func changeInputBar(_ isBlocked: Bool)
}

protocol ChatWorkerLogic {
    func createChat(_ memberID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void)
    func setExpirationTime(
        _ chatID: UUID,
        _ expiration: String?,
        completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void
    )
    func sendTextMessage(_ chatID: UUID, _ message: String, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func saveSecretKey(_ key: String) -> Bool
    
    func deleteMessage(_ chatID: UUID, _ updateID: Int64, _ deleteMode: DeleteMode, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func editTextMessage(_ chatID: UUID, _ updateID: Int64, _ text: String, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func sendFileMessage(_ chatID: UUID, _ fileID: UUID, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func sendReaction(_ chatID: UUID, _ reaction: String, _ messageID: Int64, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func deleteReaction(_ chatID: UUID, _ updateID: Int64, completion: @escaping (Result<UpdateData, Error>) -> Void)
    
    func loadFirstMessages(_ chatID: UUID, _ from: Int64, _ to: Int64, completion: @escaping (Result<[UpdateData], Error>) -> Void)
    func loadMoreMessages()
    
    func getMyID() -> UUID
}

protocol SendingMessagesProtocol: AnyObject {
    func sendTextMessage(_ message: String, _ replyTo: Int64?, completion: @escaping (Bool) -> Void)
}
