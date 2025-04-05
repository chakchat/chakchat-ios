//
//  MockErrorHandler.swift
//  chakchat
//
//  Created by Кирилл Исаев on 16.01.2025.
//

import Foundation

// MARK: - MockErrorHandler
final class MockErrorHandler: ErrorHandlerLogic {
    
    var handledError: (any Error)?
    
    func handleError(_ error: any Error) -> ErrorId {
        handledError = error
        return ErrorId(message: nil, type: ErrorOutput.None)
    }
    
    func handleExpiredRefreshToken() {
        print("hello world")
    }
}

