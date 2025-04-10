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
        
        let interactor = SendCodeInteractor(presenter: presenter,
                                            errorHandler: context.errorHandler,
                                            logger: context.logger
        )
        
        let view = SendCodeViewController(interactor: interactor)
        presenter.view = view
        
        interactor.onRouteToVerifyScreen = { [weak coordinator] phone in
            coordinator?.showVerifyScreen(phone)
        }
        
        return view
    }
}
