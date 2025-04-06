//
//  SenderProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 16.01.2025.
//

import Foundation

// MARK: - SenderProtocols
protocol SenderLogic {
    static func send<T: Codable>(endpoint: String,
                                 method: HTTPMethod,
                                 headers: [String:String]?,
                                 body: Data?,
                                 attempt: Int,
                                 completion: @escaping (Result<SuccessResponse<T>, Error>) -> Void
    )
}
