//
//  SignupProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.01.2025.
//

import Foundation

// MARK: - Signup Protocols
protocol SignupBusinessLogic {
    func sendSignupRequest(_ name: String, _ username: String)
    func checkUsernameAvailability(_ username: String, completion: @escaping (Result<Bool, Error>) -> Void)
    func successTransition(_ state: SignupState)
}

protocol SignupPresentationLogic {
    func showError(_ error: ErrorId)
}

protocol SignupWorkerLogic {
    func sendRequest(_ request: SignupModels.SignupRequest,
                     completion: @escaping (Result<SignupState, Error>) -> Void)
    
    func getSignupCode() -> UUID?
    func checkUsernameAvailability(_ username: String, completion: @escaping (Result<SignupModels.UserExistsResponse, Error>) -> Void)
    func getDeviceToken() -> String?
}


