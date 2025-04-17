//
//  ConfidentialityScreenAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 28.01.2025.
//

import Foundation
import UIKit

// MARK: - ConfidentialityScreenAssembly
enum ConfidentialityScreenAssembly {
    
    static func build(with context: MainAppContextProtocol) -> UIViewController {
        let presenter = ConfidentialityScreenPresenter()
        let userService = UserService()
        let worker = ConfidentialityScreenWorker(userDefaultsManager: context.userDefaultsManager, userService: userService, keychainManager: context.keychainManager)
        let interactor = ConfidentialityScreenInteractor(presenter: presenter,
                                                         worker: worker,
                                                         errorHandler: context.errorHandler,
                                                         eventSubscriber: context.eventManager,
                                                         logger: context.logger)
        
        interactor.onRouteToSettingsMenu = {
            AppCoordinator.shared.popScreen()
        }
        
        interactor.onRouteToPhoneVisibilityScreen = {
            AppCoordinator.shared.showPhoneVisibilityScreen()
        }
        
        interactor.onRouteToBirthVisibilityScreen = {
            AppCoordinator.shared.showBirthVisibilityScreen()
        }
        
        interactor.onRouteToOnlineVisibilityScreen = {
            AppCoordinator.shared.showOnlineVisibilityScreen()
        }
        
        interactor.onRouteToBlackListScreen = {
            AppCoordinator.shared.showBlackListScreen()
        }
        
        let view = ConfidentialityScreenViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}

