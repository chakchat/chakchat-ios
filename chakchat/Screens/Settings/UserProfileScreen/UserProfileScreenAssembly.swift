//
//  UserProfileScreenAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 06.02.2025.
//

import Foundation
import UIKit

// MARK: - UserProfileScreenAssembly
enum UserProfileScreenAssembly {
    
    static func build(with context: MainAppContextProtocol) -> UIViewController {
        let presenter = UserProfileScreenPresenter()
        let worker = UserProfileScreenWorker(userDefaultsManager: context.userDefaultsManager, identityService: IdentityService(), keychainManager: context.keychainManager)
        let interactor = UserProfileScreenInteractor(preseter: presenter,
                                                     worker: worker,
                                                     eventSubscriber: context.eventManager,
                                                     errorHandler: context.errorHandler,
                                                     logger: context.logger)
        
        interactor.onRouteToSettingsScreen = {
            AppCoordinator.shared.popScreen()
        }
        interactor.onRouteToProfileSettingsScreen = {
            AppCoordinator.shared.showProfileSettingsScreen()
        }
        interactor.onRouteToRegistration = {
            AppCoordinator.shared.showSendCodeScreen()
        }
        let view = UserProfileScreenViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
