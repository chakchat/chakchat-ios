//
//  SecretGroupChatService.swift
//  chakchat
//
//  Created by Кирилл Исаев on 26.02.2025.
//

import Foundation

// MARK: - SecretGroupChatService
final class SecretGroupChatService: SecretGroupChatServiceProtocol {
    
    func sendCreateChatRequest(
        _ request: ChatsModels.GroupChat.CreateRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretGroupChat.Response>, any Error>) -> Void
    ) {
        let endpoint = MessagingServiceEndpoints.SecretGroupChatEndpoints.secretGroupChat.rawValue
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
    
    func sendUpdateChatRequest(
        _ chatID: UUID,
        _ request: ChatsModels.GroupChat.UpdateRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretGroupChat.Response>, any Error>) -> Void
    ) {
        let endpoint = "\(MessagingServiceEndpoints.SecretGroupChatEndpoints.secretGroupChat.rawValue)/\(chatID)"
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .put, headers: headers, body: body, completion: completion)
    }
    
    func sendDeleteChatRequest(
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<EmptyResponse>, any Error>) -> Void
    ) {
        let endpoint = "\(MessagingServiceEndpoints.SecretGroupChatEndpoints.secretGroupChat.rawValue)/\(chatID)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .delete, headers: headers, completion: completion)
    }
    
    func sendAddMemberRequest(
        _ chatID: UUID,
        _ memberID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretGroupChat.Response>, any Error>) -> Void
    ) {
        let endpoint = "\(MessagingServiceEndpoints.SecretGroupChatEndpoints.secretGroupChat.rawValue)/\(chatID)/member/\(memberID)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .put, headers: headers, completion: completion)
    }
    
    func sendDeleteMemberRequest(
        _ chatID: UUID,
        _ memberID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretGroupChat.Response>, any Error>) -> Void
    ) {
        let endpoint = "\(MessagingServiceEndpoints.SecretGroupChatEndpoints.secretGroupChat.rawValue)/\(chatID)/member/\(memberID)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .delete, headers: headers, completion: completion)
    }
    
    func sendUpdatePhotoRequest(
        _ request: ChatsModels.GroupChat.PhotoUpdateRequest,
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretGroupChat.Response>, any Error>) -> Void
    ) {
        let endpoint = "\(MessagingServiceEndpoints.SecretGroupChatEndpoints.secretGroupChat.rawValue)/\(chatID)/photo"
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .put, headers: headers, body: body, completion: completion)
    }
    
    func sendDeletePhotoRequest(
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretGroupChat.Response>, any Error>) -> Void
    ) {
        let endpoint = "\(MessagingServiceEndpoints.SecretGroupChatEndpoints.secretGroupChat.rawValue)/\(chatID)/photo"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .delete, headers: headers, completion: completion)
    }
}
