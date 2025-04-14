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
    func passChatData()
    func handleAddedMemberEvent(_ event: AddedMemberEvent)
    func handleDeletedMemberEvent(_ event: DeletedMemberEvent)
    
    func loadFirstMessages(completion: @escaping (Result<[MessageType], Error>) -> Void)
}

protocol GroupChatPresentationLogic {
    func passChatData(_ chatData: ChatsModels.GeneralChatModel.ChatData)
}

protocol GroupChatWorkerLogic {
    func sendTextMessage(_ message: String)
    
    func loadFirstMessages(_ chatID: UUID, _ from: Int64, _ to: Int64, completion: @escaping (Result<[UpdateData], Error>) -> Void)
}
