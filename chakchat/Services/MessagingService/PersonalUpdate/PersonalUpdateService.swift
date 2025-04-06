//
//  UpdateService.swift
//  chakchat
//
//  Created by Кирилл Исаев on 26.02.2025.
//

import Foundation

// MARK: - UpdateService
final class UpdateService: UpdateServiceProtocol {
    
    private let baseAPI: String = "/api/messaging/v1.0/"
    
    func sendGetUpdatesRequest(
        _ chatID: UUID,
        _ from: Int64,
        _ to: Int64,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)\(MessaginServiceEndpoints.UpdateEndpoints.getUpdatesInRange.rawValue)"
        var components = URLComponents(string: endpoint)
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "from", value: String(from)))
        queryItems.append(URLQueryItem(name: "to", value: String(to)))
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let endpointWithQuery = url.absoluteString
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpointWithQuery, method: .get, headers: headers, completion: completion)
    }
    
    func sendSearchForMessageRequest(
        _ chatID: UUID,
        _ offset: Int64,
        _ limit: Int64,
        _ pattern: String?,
        _ senderID: UUID?,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)\(MessaginServiceEndpoints.UpdateEndpoints.searchForMessages.rawValue)"
        var components = URLComponents(string: endpoint)
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "from", value: String(offset)))
        queryItems.append(URLQueryItem(name: "to", value: String(limit)))
        
        if let pattern = pattern {
            queryItems.append(URLQueryItem(name: "pattern", value: pattern))
        }
        if let senderID = senderID {
            queryItems.append(URLQueryItem(name: "sender_id", value: senderID.uuidString))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let endpointWithQuery = url.absoluteString
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpointWithQuery, method: .get, headers: headers, completion: completion)
    }
    
    func sendPutTextMessageRequest(
        _ request: ChatsModels.UpdateModels.SendMessageRequest,
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)\(MessaginServiceEndpoints.UpdateEndpoints.sendTextMessage.rawValue)"
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
        _ deleteMode: DeleteMode,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<EmptyResponse>, any Error>) -> Void
    ) {
        let endpoint = 
        "\(baseAPI)\(chatID)\(MessaginServiceEndpoints.UpdateEndpoints.deleteMessage.rawValue)\(updateID)/delete/\(deleteMode)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .delete, headers: headers, completion: completion)
    }
    
    func sendEditTextMessageRequest(
        _ chatID: UUID,
        _ updateID: Int64,
        _ request: ChatsModels.UpdateModels.EditMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, any Error>) -> Void
    ) {
        let endpoint =
        "\(baseAPI)\(chatID)\(MessaginServiceEndpoints.UpdateEndpoints.sendTextMessage)/\(updateID)"
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .put, headers: headers, body: body, completion: completion)
    }
    
    func sendFileMessageRequest(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.FileMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, any Error>) -> Void
    ) {
        let endpoint =
        "\(baseAPI)\(chatID)\(MessaginServiceEndpoints.UpdateEndpoints.sendFileMessage)"
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
    
    func sendReactionMessageRequest(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ReactionRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Reaction>, any Error>) -> Void
    ) {
        let endpoint =
        "\(baseAPI)\(chatID)\(MessaginServiceEndpoints.UpdateEndpoints.sendReaction)"
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
    
    func sendDeleteReactionRequest(
        _ chatID: UUID,
        _ updateID: Int64,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<EmptyResponse>, any Error>) -> Void
    ) {
        let endpoint =
        "\(baseAPI)\(chatID)\(MessaginServiceEndpoints.UpdateEndpoints.sendReaction)/\(updateID)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .delete, headers: headers, completion: completion)
    }
    
    func sendForwardMessageRequest(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ForwardMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, any Error>) -> Void
    ) {
        let endpoint =
        "\(baseAPI)\(chatID)\(MessaginServiceEndpoints.UpdateEndpoints.forwardMessage)"
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
}
