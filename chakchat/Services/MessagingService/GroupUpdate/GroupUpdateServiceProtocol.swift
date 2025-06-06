//
//  GroupUpdateServiceProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 05.04.2025.
//

import Foundation

protocol GroupUpdateServiceProtocol {
    
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
        completion: @escaping (Result<SuccessResponse<UpdateData>, Error>) -> Void
    )
    
    func editTextMessage(
        _ chatID: UUID,
        _ updateID: Int64,
        _ request: ChatsModels.UpdateModels.EditMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, Error>) -> Void
    )
    
    func sendFileMessage(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.FileMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, Error>) -> Void
    )
    
    func sendReaction(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ReactionRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, Error>) -> Void
    )
    
    func deleteReaction(
        _ chatID: UUID,
        _ updateID: Int64,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, Error>) -> Void
    )
    
    func forwardTextMessage(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ForwardMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, Error>) -> Void
    )
    
    func forwardFileMessage(
        _ chatID: UUID,
        _ request: ChatsModels.UpdateModels.ForwardMessageRequest,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<UpdateData>, Error>) -> Void
    )
}
