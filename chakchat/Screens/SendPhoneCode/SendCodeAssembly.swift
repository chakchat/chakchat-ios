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
    
    // MARK: - Assembly Method
    static func build(with context: SignupContextProtocol, coordinator: AppCoordinator) -> UIViewController {
        
        let presenter = SendCodePresenter()
        let sendCodeService = SendCodeService()
        
        let worker = SendCodeWorker(sendCodeService: sendCodeService, keychainManager: context.keychainManager, userDefaultsManager: context.userDefaultsManager)
        
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
