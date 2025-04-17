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
    
    static func build(with context: SignupContextProtocol, phone: String) -> UIViewController {
        
        let presenter = VerifyPresenter()
        let identityService = IdentityService()
        
        let worker = VerifyWorker(
            identityService: identityService,
            keychainManager: context.keychainManager,
            userDefaultsManager: context.userDefaultsManager
        )
        
        let interactor = VerifyInteractor(
            presenter: presenter,
            worker: worker,
            errorHandler: context.errorHandler,
            logger: context.logger,
            phone: phone
        )
        interactor.sendCodeRequest(phone)
        let view = VerifyViewController(interactor: interactor)
        presenter.view = view
        
        interactor.onRouteToSignupScreen = { [weak context] state in
            context?.state = state
            print(state)
            AppCoordinator.shared.showSignupScreen()
        }
        
        interactor.onRouteToChatScreen = { [weak context] state in
            context?.state = state
            print(state)
            AppCoordinator.shared.setChatsScreen()
        }
        
        interactor.onRouteToSendCodeScreen = { [weak context] state in
            context?.state = state
            print(state)
            AppCoordinator.shared.popScreen()
        }
        
        return view
    }
}
