//
//  ErrorHandlerProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 16.01.2025.
//

import Foundation

// MARK: - ErrorHandlerProtocols
protocol ErrorHandlerLogic {
    func handleError(_ error: Error) -> ErrorId
    func handleExpiredRefreshToken()
}
