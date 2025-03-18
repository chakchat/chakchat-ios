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
    
    static func build(with context: SignupContextProtocol, coordinator: AppCoordinator) -> UIViewController {
        let presenter = SignupPresenter()
        let identityService = IdentityService()
        
        let worker = SignupWorker(
            keychainManager: context.keychainManager,
            userDefautlsManager: context.userDefaultsManager,
            identityService: identityService
        )
        
        let interactor = SignupInteractor(
            presenter: presenter,
            worker: worker,
            state: context.state,
            errorHandler: context.errorHandler,
            logger: context.logger
        )
        
        let view = SignupViewController(interactor: interactor)
        presenter.view = view
        
        interactor.onRouteToChatScreen = { [weak context, weak coordinator] state in
            context?.state = state
            print(state)
            coordinator?.setChatsScreen()
        }
        
        return view
    }
}
