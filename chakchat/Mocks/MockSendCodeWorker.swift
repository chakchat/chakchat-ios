//
//  SendCodeWorkerMock.swift
//  chakchat
//
//  Created by Кирилл Исаев on 16.01.2025.
//

import Foundation

// MARK: - MockWorker
final class MockWorker: SendCodeWorkerLogic {

    var result: Result<SignupState, Error>?
    
    func sendInRequest(_ request: SendCodeModels.SendCodeRequest, completion: @escaping (Result<SignupState, any Error>) -> Void) {
        if let result = result {
            completion(result)
        }
    }
    
    func sendUpRequest(_ request: SendCodeModels.SendCodeRequest, completion: @escaping (Result<SignupState, any Error>) -> Void) {
        if let result = result {
            completion(result)
        }
    }
}

protocol SendCodeWorkerLogic {
    func sendInRequest(_ request: SendCodeModels.SendCodeRequest, completion: @escaping (Result<SignupState, any Error>) -> Void)
    
    func sendUpRequest(_ request: SendCodeModels.SendCodeRequest, completion: @escaping (Result<SignupState, any Error>) -> Void)
}
