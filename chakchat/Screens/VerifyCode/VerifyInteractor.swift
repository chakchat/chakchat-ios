//
//  VerifyInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 08.01.2025.
//

import Foundation
import UIKit
final class VerifyInteractor: VerifyBusinessLogic {
    
    private var presentor: VerifyPresentationLogic
    private var worker: VerifyWorkerLogic
    private var errorHandler: ErrorHandlerLogic
    var state: AppState
    
    var onRouteToSignupScreen: ((AppState) -> Void)?
    var onRouteToChatScreen: ((AppState) -> Void)?
    var onRouteToSendCodeScreen: ((AppState) -> Void)?
    
    init(presentor: VerifyPresentationLogic,
         worker: VerifyWorkerLogic,
         errorHandler: ErrorHandlerLogic,
         state: AppState) {
        self.presentor = presentor
        self.worker = worker
        self.errorHandler = errorHandler
        self.state = state
    }
    
    func sendVerificationRequest(_ code: String) {
        print("Send request to worker")
        if (state == AppState.signin) {
            let key = worker.getVerifyCode(KeychainManager.keyForSaveSigninCode)
            worker.sendVerificationRequest(Verify.VerifySigninRequest(signinKey: key!, code: code),                 SigninEndpoints.signinEndpoint.rawValue, SuccessModels.Tokens.self) { [weak self] result in
                guard let self = self else {return}
                switch result {
                case .success(let state):
                    self.routeToChatScreen(state)
                case .failure(let error):
                    let errorId = self.errorHandler.handleError(error)
                    self.presentor.showError(errorId)
                }
            }
        } else if (state == AppState.signupVerifyCode) {
            let key = worker.getVerifyCode(KeychainManager.keyForSaveSignupCode)
            worker.sendVerificationRequest(Verify.VerifySignupRequest(signupKey: key!, code: code), SignupEndpoints.verifyCodeEndpoint.rawValue, SuccessModels.VerifySignupData.self) { [weak self] result in
                guard let self = self else {return}
                switch result {
                case .success(let state):
                    self.routeToSignupScreen(state)
                case .failure(let error):
                    let errorId = self.errorHandler.handleError(error)
                    self.presentor.showError(errorId)
                }
            }
        }
//        routeToSignupScreen(AppState.signup)
    }
    
    func routeToSignupScreen(_ state: AppState) {
        onRouteToSignupScreen?(state)
    }
    
    func routeToChatScreen(_ state: AppState) {
        onRouteToChatScreen?(state)
    }
    
    func routeToSendCodeScreen(_ state: AppState) {
        onRouteToSendCodeScreen?(state)
    }
}
