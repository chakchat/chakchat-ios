//
//  SecretPersonalChatService.swift
//  chakchat
//
//  Created by Кирилл Исаев on 26.02.2025.
//

import Foundation

// MARK: - SecretPersonalChatService
final class SecretPersonalChatService: SecretPersonalChatServiceProtocol {
    
    func sendCreateChatRequest(
        _ request: ChatsModels.PersonalChat.CreateRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.ChatData>, any Error>) -> Void
    ) {
        let endpoint = MessagingServiceEndpoints.SecretPersonalChatEndpoints.secretPersonalChat.rawValue
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
    
    func sendSetExpirationRequest(
        _ request: ChatsModels.SecretPersonalChat.ExpirationRequest,
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.ChatData>, any Error>) -> Void
    ) {
        let endpoint = "\(MessagingServiceEndpoints.SecretPersonalChatEndpoints.secretPersonalChat.rawValue)/\(chatID)/expiration"
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .put, headers: headers, body: body, completion: completion)
    }
    
    func sendDeleteChatRequest(
        _ chatID: UUID,
        _ deleteMode: DeleteMode,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<EmptyResponse>, any Error>) -> Void
    ) {
        let endpoint = "\(MessagingServiceEndpoints.SecretPersonalChatEndpoints.secretPersonalChat.rawValue)/\(chatID)/delete/\(deleteMode)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .delete, headers: headers, completion: completion)
    }
}
