//
//  SettingsScreenAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 21.01.2025.
//

import Foundation
import UIKit

// MARK: - SettingsScreenAssembly
enum SettingsScreenAssembly {
    
    static func build(with context: MainAppContextProtocol) -> UIViewController {
        let presenter = SettingsScreenPresenter()
        let userService = UserService()
        let worker = SettingsScreenWorker(userDefaultsManager: context.userDefaultsManager, userService: userService, keychainManager: context.keychainManager)
       
        let interactor = SettingsScreenInteractor(presenter: presenter,
                                                  worker: worker,
                                                  eventSubscriber: context.eventManager, 
                                                  errorHandler: context.errorHandler,
                                                  logger: context.logger
        )
        interactor.onRouteToUserProfileSettings = {
            AppCoordinator.shared.showUserSettingsScreen()
        }
        interactor.onRouteToConfidentialitySettings = {
           AppCoordinator.shared.showConfidentialityScreen()
        }
        interactor.onRouteToNotificationsSettings = {
            AppCoordinator.shared.showNotificationScreen()
        }
        interactor.onRouteToLanguageSettings = {
            AppCoordinator.shared.showLanguageScreen()
        }
        interactor.onRouteToAppThemeSettings = {
            AppCoordinator.shared.showAppThemeScreen()
        }
        interactor.onRouteToCacheSettings = {
            AppCoordinator.shared.showCacheScreen()
        }
        interactor.onRouteToHelpSettings = {
            AppCoordinator.shared.showHelpScreen()
        }
        
        let view = SettingsScreenViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
