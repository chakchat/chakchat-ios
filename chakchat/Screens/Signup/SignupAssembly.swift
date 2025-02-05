//
//  SignupAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.01.2025.
//

import Foundation
import UIKit

// MARK: - SignupAssenbly
enum SignupAssembly {
    
    // MARK: - Assembly Method
    static func build(with context: SignupContextProtocol, coordinator: AppCoordinator) -> UIViewController {
        let presenter = SignupPresenter()
        let signupService: SignupServiceLogic = SignupService()
        
        let worker = SignupWorker(keychainManager: context.keychainManager, userDefautlsManager: context.userDefaultsManager, signupService: signupService)
        
        let interactor = SignupInteractor(presenter: presenter, 
                                          worker: worker,
                                          state: context.state,
                                          errorHandler: context.errorHandler)
        
        let view = SignupViewController(interactor: interactor)
        presenter.view = view
        
        interactor.onRouteToChatScreen = { [weak context, weak coordinator] state in
            context?.state = state
            print(state)
            coordinator?.finishSignupFlow()
        }
        
        return view
    }
}
