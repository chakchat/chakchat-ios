//
//  ChatsService.swift
//  chakchat
//
//  Created by Кирилл Исаев on 26.02.2025.
//

import Foundation

// MARK: - ChatsService
final class ChatsService: ChatsServiceProtocol {
    
    func sendGetChatsRequest(
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.ChatsData>, any Error>) -> Void
    ) {
        let endpoint = "\(MessagingServiceEndpoints.ChatsEndpoints.getAllChats.rawValue)?preview=1"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .get, headers: headers, completion: completion)
    }
    
    func sendGetChatRequest(
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.ChatsData>, any Error>) -> Void
    ) {
        let endpoint = "\(MessagingServiceEndpoints.ChatsEndpoints.getConcreteChat.rawValue)\(chatID)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .get, headers: headers, completion: completion)
    }
}
