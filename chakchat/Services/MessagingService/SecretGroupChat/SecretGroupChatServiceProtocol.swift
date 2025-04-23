//
//  SecretGroupChatServiceProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 26.02.2025.
//

import Foundation

// MARK: - SecretGroupChatServiceProtocol
protocol SecretGroupChatServiceProtocol {
    func sendCreateChatRequest(
        _ request: ChatsModels.GroupChat.CreateRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.ChatData>, Error>) -> Void
    )
    
    func sendUpdateChatRequest(
        _ chatID: UUID,
        _ request: ChatsModels.GroupChat.UpdateRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretGroupChat.Response>, Error>) -> Void
    )
    
    func sendDeleteChatRequest(
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<EmptyResponse>, Error>) -> Void
    )
    
    func sendAddMemberRequest(
        _ chatID: UUID,
        _ memberID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretGroupChat.Response>, Error>) -> Void
    )
    
    func sendDeleteMemberRequest(
        _ chatID: UUID,
        _ memberID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretGroupChat.Response>, Error>) -> Void
    )
    
    func sendUpdatePhotoRequest(
        _ request: ChatsModels.GroupChat.PhotoUpdateRequest,
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretGroupChat.Response>, Error>) -> Void
    )
    
    func sendDeletePhotoRequest(
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretGroupChat.Response>, Error>) -> Void
    )
}
