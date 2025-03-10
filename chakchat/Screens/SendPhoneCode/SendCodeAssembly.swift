//
//  RegistrationAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.01.2025.
//

import Foundation
import UIKit

// MARK: - SendCodeAssembly
enum SendCodeAssembly {
    
    static func build(with context: SignupContextProtocol, coordinator: AppCoordinator) -> UIViewController {
        
        let presenter = SendCodePresenter()
        let identityService = IdentityService()
        
        let worker = SendCodeWorker(identityService: identityService, 
                                    keychainManager: context.keychainManager,
                                    userDefaultsManager: context.userDefaultsManager)
        
        let interactor = SendCodeInteractor(presenter: presenter, 
                                            worker: worker, 
                                            state: context.state,
                                            errorHandler: context.errorHandler,
                                            logger: context.logger
        )
        
        let view = SendCodeViewController(interactor: interactor)
        presenter.view = view
        
        interactor.onRouteToVerifyScreen = { [weak context, weak coordinator] state in
            context?.state = state
            print(state)
            coordinator?.showVerifyScreen()
        }
        
        return view
    }
}
