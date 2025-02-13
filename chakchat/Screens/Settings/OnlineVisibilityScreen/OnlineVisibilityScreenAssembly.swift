//
//  OnlineVisibilityScreenAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 31.01.2025.
//

import Foundation
import UIKit

// MARK: - OnlineVisibilityScreenAssembly
enum OnlineVisibilityScreenAssembly {
    // MARK: - Online Visibility Screen Assembly Method
    static func build(with context: MainAppContextProtocol, coordinator: AppCoordinator) -> UIViewController {
        let presenter = OnlineVisibilityScreenPresenter()
        let worker = OnlineVisibilityScreenWorker(userDeafultsManager: context.userDefaultsManager)
        let interactor = OnlineVisibilityScreenInteractor(presenter: presenter, 
                                                          worker: worker,
                                                          eventManager: context.eventManager,
                                                          onlineRestrictionSnap: OnlineVisibilityStatus(status: context.userDefaultsManager.loadOnlineStatus()),
                                                          logger: context.logger
        )
        interactor.onRouteToConfidentialityScreen = { [weak coordinator] in
            coordinator?.popScreen()
        }
        let view = OnlineVisibilityScreenViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
