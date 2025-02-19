//
//  ProfileSettingsAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.01.2025.
//

import Foundation
import UIKit

// MARK: - ProfileSettingsAssembly
enum ProfileSettingsAssembly {
    
    // MARK: - Profile Setting Assembly Method
    static func build(with context: MainAppContextProtocol, coordinator: AppCoordinator) -> UIViewController {
        let presenter = ProfileSettingsPresenter()
        let meService = MeService()
        let fileStorageService = FileStorageService()
        let identityService = IdentityService()
        let worker = ProfileSettingsWorker(
            userDefaultsManager: context.userDefaultsManager,
            meService: meService,
            fileStorageService: fileStorageService,
            identityService: identityService,
            keychainManager: context.keychainManager
        )
        let interactor = ProfileSettingsInteractor(
            presenter: presenter,
            worker: worker,
            eventPublisher: context.eventManager,
            errorHandler: context.errorHandler,
            logger: context.logger
        )
        
        interactor.onRouteToSettingsMenu = { [weak coordinator] in
            coordinator?.popScreen()
        }
        interactor.onRouteToRegistration = { [weak coordinator] in
            coordinator?.showRegistrationScreen()
        }
        let view = ProfileSettingsViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}

