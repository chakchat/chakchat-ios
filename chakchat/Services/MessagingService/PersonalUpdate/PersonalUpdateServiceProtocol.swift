//
//  UpdateServiceProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 26.02.2025.
//

import Foundation

// MARK: - UpdateServiceProtocol
protocol UpdateServiceProtocol {
    func sendGetUpdatesRequest(
        _ chatID: UUID,
        _ from: Int64,
        _ to: Int64,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, Error>) -> Void
    )
    
    func sendSearchForMessageRequest(
        _ chatID: UUID,
        _ offset: Int64,
        _ limit: Int64,
        _ pattern: String?,
        _ senderID: UUID?,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, Error>) -> Void
    )
    
    func sendPutTextMessageRequest(
        _ request: ChatsModels.UpdateModels.SendMessageRequest,
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, Error>) -> Void
    )
    
    func sendDeleteMessageRequest(
        _ chatID: UUID,
        _ updateID: Int64,
        _ deleteMode: DeleteMode,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<EmptyResponse>, Error>) -> Void
    )
    
    func sendEditTextMessageRequest(
        _ chatID: UUID,
        _ updateID: Int64,
        _ request: ChatsModels.UpdateModels.EditMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, Error>) -> Void
    )
    
    func sendFileMessageRequest(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.FileMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, Error>) -> Void
    )
    
    func sendReactionMessageRequest(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ReactionRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Reaction>, Error>) -> Void
    )
    
    func sendDeleteReactionRequest(
        _ chatID: UUID,
        _ updateID: Int64,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<EmptyResponse>, Error>) -> Void
    )
    
    func sendForwardMessageRequest(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ForwardMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, Error>) -> Void
    )
}
