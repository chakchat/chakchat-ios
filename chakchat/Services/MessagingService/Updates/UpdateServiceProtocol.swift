//
//  UpdateServiceProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 14.04.2025.
//

import Foundation

protocol UpdateServiceProtocol {
    func getUpdatesInRange(
        _ chatID: UUID,
        _ from: Int64,
        _ to: Int64,
        _ accessToken: String,
        completion: @escaping (Result<Updates, any Error>) -> Void
    ) 
}
