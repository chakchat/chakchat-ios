//
//  GroupUpdateService.swift
//  chakchat
//
//  Created by Кирилл Исаев on 05.04.2025.
//

import Foundation

final class GroupUpdateService: GroupUpdateServiceProtocol {
    
    private let baseAPI: String = "/api/messaging/v1.0/chat/group/"
    
    func searchForMessages(
        _ chatID: UUID,
        _ offset: Int64,
        _ limit: Int64,
        _ pattern: String?,
        _ senderID: UUID?,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)/\(MessagingServiceEndpoints.PersonalUpdateEndpoints.searchMessages)"
        
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
    
    func sendTextMessage(
        _ request: ChatsModels.UpdateModels.SendMessageRequest,
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)/\(MessagingServiceEndpoints.PersonalUpdateEndpoints.sendTextMessage.rawValue)"
        
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
    
    func deleteMessage(
        _ chatID: UUID,
        _ updateID: Int64,
        _ deleteMode: DeleteMode,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)/\(MessagingServiceEndpoints.PersonalUpdateEndpoints.updateMessage.rawValue)/\(updateID)/\(deleteMode.rawValue)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .delete, headers: headers, completion: completion)
    }
    
    func editTextMessage(
        _ chatID: UUID,
        _ updateID: Int64,
        _ request: ChatsModels.UpdateModels.EditMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)/\(MessagingServiceEndpoints.PersonalUpdateEndpoints.sendTextMessage.rawValue)/\(updateID)"
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .put, headers: headers, body: body, completion: completion)
    }
    
    func sendFileMessage(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.FileMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)\(MessagingServiceEndpoints.PersonalUpdateEndpoints.sendFile.rawValue)"
        
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
    
    func sendReaction(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ReactionRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)/\(MessagingServiceEndpoints.PersonalUpdateEndpoints.sendReaction.rawValue)"
        
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
    
    func deleteReaction(
        _ chatID: UUID,
        _ updateID: Int64,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, any Error>) -> Void
    ) {
        let endpoint =  "\(baseAPI)\(chatID)/\(MessagingServiceEndpoints.PersonalUpdateEndpoints.sendReaction.rawValue)/\(updateID)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .delete, headers: headers, completion: completion)
    }
    
    func forwardTextMessage(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ForwardMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)/\(MessagingServiceEndpoints.PersonalUpdateEndpoints.forwardMessage.rawValue)"
        
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
    
    func forwardFileMessage(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ForwardMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, any Error>) -> Void
    ) {
        let endpoint = "\(baseAPI)\(chatID)/\(MessagingServiceEndpoints.PersonalUpdateEndpoints.forwardFile.rawValue)"
        
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
