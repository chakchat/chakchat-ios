//
//  SecretGroupUpdateProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 06.04.2025.
//

import Foundation

protocol SecretGroupUpdateProtocol {
    func sendSecretMessage(
        _ request: ChatsModels.SecretUpdateModels.SendMessageRequest,
        _ chatID: UUID,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<ChatsModels.SecretUpdateModels.SecretPreview>, Error>) -> Void
    )
    
    func deleteSecretMessage(
        _ chatID: UUID,
        _ updateID: Int64,
        _ accessToken: String,
        completion: @escaping (Result<SuccessResponse<EmptyResponse>, Error>) -> Void
    )
}
