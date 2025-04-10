//
//  VerifyInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 08.01.2025.
//

import Foundation
import OSLog
 
// MARK: - VerifyInteractor
final class VerifyInteractor: VerifyBusinessLogic {
    // MARK: - Properties
    private let presenter: VerifyPresentationLogic
    private let worker: VerifyWorkerLogic
    private let errorHandler: ErrorHandlerLogic
    private var state: SignupState = .signupVerifyCode
    private let logger: OSLog
    
    private let phone: String
    
    var onRouteToSignupScreen: ((SignupState) -> Void)?
    var onRouteToChatScreen: ((SignupState) -> Void)?
    var onRouteToSendCodeScreen: ((SignupState) -> Void)?
    
    // MARK: - Initialization
    init(presenter: VerifyPresentationLogic,
         worker: VerifyWorkerLogic,
         errorHandler: ErrorHandlerLogic,
         logger: OSLog,
         phone: String
    ) {
        self.presenter = presenter
        self.worker = worker
        self.errorHandler = errorHandler
        self.logger = logger
        self.phone = phone
    }
    
    // MARK: - Public Methods
    func sendCodeRequest(_ phone: String) {
        let request = SendCodeModels.SendCodeRequest(phone: phone)
        worker.sendInRequest(request) { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .success(let state):
                os_log("Code received, saved", log: logger, type: .info)
                self.state = state
            case .failure(let error):
                let errorId = self.errorHandler.handleError(error)
                self.presenter.showError(errorId)
            }
        }
    }
    
    func sendVerificationRequest(_ code: String) {
        os_log("Sent code to server", log: logger, type: .info)
        
        if (state == SignupState.signin) {
            guard let key = worker.getVerifyCode(KeychainManager.keyForSaveSigninCode) else {
                os_log("Can't find verify key in keychain storage", log: logger, type: .fault)
                return
            }

            worker.sendVerificationRequest(VerifyModels.VerifySigninRequest(signinKey: key, code: code),                 IdentityServiceEndpoints.signinEndpoint.rawValue, SuccessModels.Tokens.self) { [weak self] result in
                guard let self = self else {return}
                switch result {
                case .success(let state):
                    os_log("Code verified", log: logger, type: .info)
                    self.routeToChatScreen(state)
                case .failure(let error):
                    let errorId = self.errorHandler.handleError(error)
                    self.presenter.showError(errorId)
                }
            }
        } else if (state == SignupState.signupVerifyCode) {
            guard let key = worker.getVerifyCode(KeychainManager.keyForSaveSignupCode) else {
                os_log("Can't find verify key in keychain storage", log: logger, type: .fault)
                return
            }
            
            worker.sendVerificationRequest(VerifyModels.VerifySignupRequest(signupKey: key, code: code), IdentityServiceEndpoints.verifyCodeEndpoint.rawValue, SuccessModels.EmptyResponse.self) { [weak self] result in
                guard let self = self else {return}
                switch result {
                case .success(let state):
                    os_log("Code verified", log: logger, type: .info)
                    self.routeToSignupScreen(state)
                case .failure(let error):
                    let errorId = self.errorHandler.handleError(error)
                    self.presenter.showError(errorId)
                }
            }
        }
    }
    
    func getPhone() {
        presenter.showPhone(phone)
    }
    
    func resendCodeRequest(_ request: VerifyModels.ResendCodeRequest) {
        os_log("Sent resend code request to server", log: logger, type: .info)
        if (state == SignupState.signin) {
            worker.resendInRequest(request) { [weak self] result in
                guard let self = self else {return}
                switch result {
                case .success(_):
                    self.successTransition()
                    os_log("Resent code to user", log: logger, type: .info)
                case .failure(let error):
                    let errorId = self.errorHandler.handleError(error)
                    self.presenter.showError(errorId)
                }
            }
        } else if (state == SignupState.signupVerifyCode) {
            worker.resendUpRequest(request) { [weak self] result in
                guard let self = self else {return}
                switch result {
                case .success(_):
                    self.successTransition()
                    os_log("Resent code to user", log: logger, type: .info)
                case .failure(let error):
                    let errorId = self.errorHandler.handleError(error)
                    self.presenter.showError(errorId)
                }
            }
        }
    }
    
    // MARK: - Routing
    func routeToSignupScreen(_ state: SignupState) {
        os_log("Routed to signup screen", log: logger, type: .default)
        onRouteToSignupScreen?(state)
    }
    
    func routeToChatScreen(_ state: SignupState) {
        os_log("Routed to chat menu screen", log: logger, type: .default)
        onRouteToChatScreen?(state)
    }
    
    func routeToSendCodeScreen(_ state: SignupState) {
        os_log("Routed to send code screen", log: logger, type: .default)
        onRouteToSendCodeScreen?(state)
    }
    
    func successTransition() {
        presenter.hideResendButton()
    }
}
