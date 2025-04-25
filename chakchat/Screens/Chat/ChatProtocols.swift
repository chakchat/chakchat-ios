//
//  ChatProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import Foundation
import UIKit
import MessageKit

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
    func loadFirstMessages(completion: @escaping (Result<[MessageType], Error>) -> Void)
    func pollNewMessages(_ from: Int64, completion: @escaping (Result<[any MessageType], any Error>) -> Void)
    
    func loadSavedMessages() -> [MessageType]
    func getLastUpdateID() -> Int64?
    
    func deleteMessage(_ updateID: Int64, _ deleteMode: DeleteMode, completion: @escaping (Result<UpdateData, any Error>) -> Void)
    func editTextMessage(_ updateID: Int64, _ text: String, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func sendFileMessage(_ fileID: UUID, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func sendReaction(_ reaction: String, _ messageID: Int64, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func deleteReaction(_ updateID: Int64, completion: @escaping (Result<UpdateData, Error>) -> Void)
    
    func forwardMessage(_ message: Int64, _ forwardType: ForwardType)
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<UpdateData, any Error>) -> Void)
    func uploadVideo(_ videoURL: URL, completion: @escaping (Result<UpdateData, any Error>) -> Void)
    func uploadFile(_ fileURL: URL, _ mimeType: String?, completion: @escaping (Result<UpdateData, any Error>) -> Void)
    
    func mapToTextMessage(_ update: UpdateData) -> GroupTextMessage
    func mapToEditedMessage(_ update: UpdateData) -> GroupTextMessageEdited
    func mapToFileMessage(_ update: UpdateData) -> GroupFileMessage
    
    func checkForSecretKey()
}

protocol ChatPresentationLogic {
    func passUserData(_ chatData: ChatsModels.GeneralChatModel.ChatData?, _ userData: ProfileSettingsModels.ProfileUserData, _ isSecret: Bool, _ myID: UUID)
    func showSecretKeyFail()
    
    func showSecretKeyAlert()
    
    func changeInputBar(_ isBlocked: Bool)
}

protocol ChatWorkerLogic {
    func createChat(_ memberID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void)
    func setExpirationTime(
        _ chatID: UUID,
        _ expiration: String?,
        completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void
    )
    func sendTextMessage(
        _ chatID: UUID,
        _ message: String,
        _ replyTo: Int64?,
        _ chatType: ChatType,
        completion: @escaping (Result<UpdateData, any Error>) -> Void
    )
    
    func saveSecretKey(_ key: String, _ chatID: UUID) -> Bool
    
    func deleteMessage(_ chatID: UUID, _ updateID: Int64, _ deleteMode: DeleteMode, _ chatType: ChatType, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func editTextMessage(_ chatID: UUID, _ updateID: Int64, _ text: String, _ chatType: ChatType, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func sendFileMessage(_ chatID: UUID, _ fileID: UUID, _ replyTo: Int64?, _ chatType: ChatType, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func sendReaction(_ chatID: UUID, _ reaction: String, _ messageID: Int64, _ chatType: ChatType, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func deleteReaction(_ chatID: UUID, _ updateID: Int64, _ chatType: ChatType, completion: @escaping (Result<UpdateData, Error>) -> Void)
    
    func uploadImage(_ fileData: Data,
                     _ fileName: String,
                     _ mimeType: String,
                     completion: @escaping (Result<SuccessModels.UploadResponse, Error>) -> Void)
    
    func openMessage(_ chatID: UUID, _ payload: Data, _ iv: Data, _ sendedKeyHash: Data) -> Data?
    
    func loadFirstMessages(_ chatID: UUID, _ from: Int64, _ to: Int64, completion: @escaping (Result<[UpdateData], Error>) -> Void)
    func loadMoreMessages()
    
    func getMyID() -> UUID
    
    func getSecretKey(_ chatID: UUID) -> String?
    
    func saveTextUpdate(_ update: UpdateData)
    func saveEditUpdate(_ update: UpdateData)
    func saveFileUpdate(_ update: UpdateData)
    func saveReactionUpdate(_ update: UpdateData)
    func saveDeleteUpdate(_ update: UpdateData)
    
    func getLastUpdateID(_ chatID: UUID) -> Int64?
    
    func loadChatMessages(_ chatID: UUID) -> [UpdateData]
}

protocol SendingMessagesProtocol: AnyObject {
    func sendTextMessage(_ message: String, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, Error>) -> Void)
}
