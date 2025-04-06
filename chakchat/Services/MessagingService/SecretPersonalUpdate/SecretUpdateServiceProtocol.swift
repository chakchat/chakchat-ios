//
//  SecretUpdateServiceProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 26.02.2025.
//

import Foundation

// MARK: - SecretUpdateServiceProtocol
protocol SecretUpdateServiceProtocol {
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
