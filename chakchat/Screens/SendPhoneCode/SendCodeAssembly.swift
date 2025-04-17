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
    
    static func build(with context: SignupContextProtocol) -> UIViewController {
        
        let presenter = SendCodePresenter()
        
        let interactor = SendCodeInteractor(presenter: presenter,
                                            errorHandler: context.errorHandler,
                                            logger: context.logger
        )
        
        let view = SendCodeViewController(interactor: interactor)
        presenter.view = view
        
        interactor.onRouteToVerifyScreen = { phone in
            AppCoordinator.shared.showVerifyScreen(phone)
        }
        
        return view
    }
}
