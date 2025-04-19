//
//  PhoneVisibilityScreenAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 30.01.2025.
//

import Foundation
import UIKit

// MARK: - PhoneVisibilityScreenAssembly
enum PhoneVisibilityScreenAssembly {
    
    static func build(with context: MainAppContextProtocol) -> UIViewController {
        let presenter = PhoneVisibilityScreenPresenter()
        let userService = UserService()
        let worker = PhoneVisibilityScreenWorker(
            userDefaultsManager: context.userDefaultsManager,
            userService: userService,
            keychainManager: context.keychainManager
        )
        let interactor = PhoneVisibilityScreenInteractor(
            presenter: presenter,
            worker: worker,
            eventManager: context.eventManager,
            errorHandler: context.errorHandler,
            logger: context.logger,
            userRestrictionsSnap: context.userDefaultsManager.loadRestrictions()
        )
        
        interactor.onRouteToConfidentialityScreen = {
            AppCoordinator.shared.popScreen()
        }
        
        interactor.onRouteToAddUsersScreen = { [weak interactor] in
            AppCoordinator.shared.showAddUsersScreen { selectedUsers in
                interactor?.selectedUsers = selectedUsers
            }
        }
        
        let view = PhoneVisibilityScreenViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}

