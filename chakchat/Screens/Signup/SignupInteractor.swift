//
//  SignupInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.01.2025.
//

import Foundation

// MARK: - SignupInteractor
final class SignupInteractor: SignupBusinessLogic {

    // MARK: - Properties
    private let presenter: SignupPresentationLogic
    private let worker: SignupWorkerLogic
    private let errorHandler: ErrorHandlerLogic
    private let state: SignupState
    
    var onRouteToChatScreen: ((SignupState) -> Void)?
    
    // MARK: - Initialization
    init(presenter: SignupPresentationLogic,
         worker: SignupWorkerLogic,
         state: SignupState,
         errorHandler: ErrorHandlerLogic) {
        
        self.presenter = presenter
        self.worker = worker
        self.state = state
        self.errorHandler = errorHandler
    }
    
    // MARK: - Signup Request
    func sendSignupRequest(_ name: String, _ username: String) {
        print("Send request to worker")
        
        guard let signupKey = worker.getSignupCode() else {
            print("Can't find signup key in keychain storage.")
            return
        }
        
        worker.sendRequest(SignupModels.SignupRequest(signupKey: signupKey, name: name, username: username)) { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .success(let state):
                self.successTransition(state)
            case .failure(let error):
                let errorId = self.errorHandler.handleError(error)
                self.presenter.showError(errorId)
            }
        }
       // successTransition(SignupState.onChatsMenu)
    }
    
    // MARK: - Routing
    func successTransition(_ state: SignupState) {
        onRouteToChatScreen?(state)
    }
}
