//
//  UpdateServiceProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 26.02.2025.
//

import Foundation

// MARK: - UpdateServiceProtocol
protocol PersonalUpdateServiceProtocol {
    func getUpdatesInRange(
        _ chatID: UUID,
        _ from: Int64,
        _ to: Int64,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, Error>) -> Void
    )
    
    func searchForMessages(
        _ chatID: UUID,
        _ offset: Int64,
        _ limit: Int64,
        _ pattern: String?,
        _ senderID: UUID?,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, Error>) -> Void
    )
    
    func sendTextMessage(
        _ request: ChatsModels.UpdateModels.SendMessageRequest,
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, Error>) -> Void
    )
    
    func deleteMessage(
        _ chatID: UUID,
        _ updateID: Int64,
        _ deleteMode: DeleteMode,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<EmptyResponse>, Error>) -> Void
    )
    
    func editTextMessage(
        _ chatID: UUID,
        _ updateID: Int64,
        _ request: ChatsModels.UpdateModels.EditMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, Error>) -> Void
    )
    
    func sendFileMessage(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.FileMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, Error>) -> Void
    )
    
    func sendReaction(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ReactionRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Reaction>, Error>) -> Void
    )
    
    func deleteReaction(
        _ chatID: UUID,
        _ updateID: Int64,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<EmptyResponse>, Error>) -> Void
    )
    
    func forwardTextMessage(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ForwardMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, Error>) -> Void
    )
    
    func forwardFileMessage(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ForwardMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.GeneralChatModel.Preview>, Error>) -> Void
    )
}
