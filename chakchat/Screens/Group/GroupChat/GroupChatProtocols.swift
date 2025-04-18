//
//  GroupChatProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit
import MessageKit

protocol GroupChatBusinessLogic: SendingMessagesProtocol {
    func routeBack()
    func routeToChatProfile()
    func routeToUserProfile(_ userID: UUID)
    func passChatData()
    func handleAddedMemberEvent(_ event: AddedMemberEvent)
    func handleDeletedMemberEvent(_ event: DeletedMemberEvent)
    
    func loadFirstMessages(completion: @escaping (Result<[MessageType], Error>) -> Void)
    func loadUsers(completion: @escaping (Result<[ProfileSettingsModels.ProfileUserData], Error>) -> Void)
    
    func deleteMessage(_ updateID: Int64, _ deleteMode: DeleteMode, completion: @escaping (Result<UpdateData, any Error>) -> Void)
    func editTextMessage(_ updateID: Int64, _ text: String, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func sendFileMessage(_ fileID: UUID, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func sendReaction(_ reaction: String, _ messageID: Int64, completion: @escaping (Bool) -> Void)
    func deleteReaction(_ updateID: Int64, completion: @escaping (Bool) -> Void)
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<UpdateData, any Error>) -> Void)
    func uploadVideo(_ videoURL: URL, completion: @escaping (Result<UpdateData, any Error>) -> Void)
    
    func mapToTextMessage(_ update: UpdateData) -> GroupTextMessage
    func mapToEditedMessage(_ update: UpdateData) -> GroupTextMessageEdited
    func mapToFileMessage(_ update: UpdateData) -> GroupFileMessage
}

protocol GroupChatPresentationLogic {
    func passChatData(_ chatData: ChatsModels.GeneralChatModel.ChatData, _ myID: UUID)
}

protocol GroupChatWorkerLogic {
    func loadFirstMessages(_ chatID: UUID, _ from: Int64, _ to: Int64, completion: @escaping (Result<[UpdateData], Error>) -> Void)
    func loadUsers(_ ids: [UUID], completion: @escaping (Result<[ProfileSettingsModels.ProfileUserData], Error>) -> Void)
    func fetchChat(_ userID: UUID) -> ChatsModels.GeneralChatModel.ChatData?
    func getMyID() -> UUID
    
    func sendTextMessage(_ chatID: UUID, _ message: String, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func deleteMessage(_ chatID: UUID, _ updateID: Int64, _ deleteMode: DeleteMode, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func editTextMessage(_ chatID: UUID, _ updateID: Int64, _ text: String, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func sendFileMessage(_ chatID: UUID, _ fileID: UUID, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func sendReaction(_ chatID: UUID, _ reaction: String, _ messageID: Int64, completion: @escaping (Result<UpdateData, Error>) -> Void)
    func deleteReaction(_ chatID: UUID, _ updateID: Int64, completion: @escaping (Result<UpdateData, Error>) -> Void)
    
    
    func uploadImage(_ fileData: Data,
                     _ fileName: String,
                     _ mimeType: String,
                     completion: @escaping (Result<SuccessModels.UploadResponse, Error>) -> Void)
}

protocol MessageEditMenuDelegate: AnyObject {
    func didTapCopy(for message: IndexPath)
    func didTapReply(for message: IndexPath)
    func didTapDelete(for message: IndexPath, mode: DeleteMode)
    func didSelectReaction(_ emoji: String, _ picked: Bool, for indexPath: IndexPath)
    func didTapReply(_ indexPath: IndexPath)
}

protocol TextMessageEditMenuDelegate: MessageEditMenuDelegate {
    func didTapEdit(for message: IndexPath)
}

protocol FileMessageEditMenuDelegate: MessageEditMenuDelegate {
    func didTapLoad(for message: IndexPath)
}
