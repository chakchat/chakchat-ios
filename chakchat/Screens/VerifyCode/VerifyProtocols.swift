//
//  VerifyProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 08.01.2025.
//

import Foundation

// MARK: - Verify Protocols
protocol VerifyBusinessLogic {
    func sendVerificationRequest(_ code: String)
    func routeToSignupScreen(_ state: SignupState)
    func routeToChatScreen(_ state: SignupState)
    func routeToSendCodeScreen(_ state: SignupState)
    func resendCodeRequest(_ request: VerifyModels.ResendCodeRequest)
    func getPhone()
}

protocol VerifyPresentationLogic {
    func showError(_ error: ErrorId)
    func showPhone(_ phone: String)
    func hideResendButton()
}

protocol VerifyWorkerLogic {
    func sendInRequest(_ request: SendCodeModels.SendCodeRequest,
                     completion: @escaping (Result<SignupState, Error>) -> Void)
    
    func sendUpRequest(_ request: SendCodeModels.SendCodeRequest,
                     completion: @escaping (Result<SignupState, Error>) -> Void)
    
    func sendVerificationRequest<Request: Codable, Response: Codable>(
        _ request: Request,
        _ endpoint: String,
        _ responseType: Response.Type,
        completion: @escaping (Result<SignupState, Error>) -> Void
    )
    
    func getVerifyCode(_ key: String) -> UUID?
    
    func getPhone() -> String
    
    func resendInRequest(_ request: VerifyModels.ResendCodeRequest,
                     completion: @escaping (Result<SignupState, Error>) -> Void)
    
    func resendUpRequest(_ request: VerifyModels.ResendCodeRequest,
                     completion: @escaping (Result<SignupState, Error>) -> Void)
}
