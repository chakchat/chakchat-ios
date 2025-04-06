//
//  SecretUpdateService.swift
//  chakchat
//
//  Created by Кирилл Исаев on 26.02.2025.
//

import Foundation

// MARK: - SecretUpdateService
final class SecretUpdateService: SecretUpdateServiceProtocol {
    
    private let baseAPI: String = "/api/messaging/v1.0/"
    
    func sendTextMessageRequest(
        _ request: ChatsModels.SecretUpdateModels.SendMessageRequest,
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretUpdateModels.SecretPreview>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)\(MessagingServiceEndpoints.SecretUpdateEndpoints.sendMessage.rawValue)"
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
    
    func sendDeleteMessageRequest(
        _ chatID: UUID,
        _ updateID: Int64,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<EmptyResponse>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)\(MessagingServiceEndpoints.SecretUpdateEndpoints.sendMessage.rawValue)\(updateID)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .delete, headers: headers, completion: completion)
    }
}
