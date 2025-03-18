//
//  VerifyAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 08.01.2025.
//

import Foundation
import UIKit

// MARK: - VerifyAssembly
enum VerifyAssembly {
    
    static func build(with context: SignupContextProtocol, coordinator: AppCoordinator) -> UIViewController {
        
        let presenter = VerifyPresenter()
        let identityService = IdentityService()
        
        let worker = VerifyWorker(
            identityService: identityService,
            keychainManager: context.keychainManager,
            userDefaultsManager: context.userDefaultsManager
        )
        
        let interactor = VerifyInteractor(
            presentor: presenter,
            worker: worker,
            errorHandler: context.errorHandler,
            state: context.state,
            logger: context.logger
        )
        let view = VerifyViewController(interactor: interactor)
        presenter.view = view
        
        interactor.onRouteToSignupScreen = { [weak context, weak coordinator] state in
            context?.state = state
            print(state)
            coordinator?.showSignupScreen()
        }
        
        interactor.onRouteToChatScreen = { [weak context, weak coordinator] state in
            context?.state = state
            print(state)
            coordinator?.setChatsScreen()
        }
        
        interactor.onRouteToSendCodeScreen = { [weak context, weak coordinator] state in
            context?.state = state
            print(state)
            coordinator?.popScreen()
        }
        
        return view
    }
}
