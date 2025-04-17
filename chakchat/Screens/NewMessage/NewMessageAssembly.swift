//
//  NewMessageAssembly.swift
//  chakchat
//
//  Created by лизо4ка курунок on 24.02.2025.
//

import UIKit

// MARK: - NewMessageAssembly
enum NewMessageAssembly {
    
    static func build(with context: MainAppContextProtocol) -> UIViewController {
        let presenter = NewMessagePresenter()
        let userService = UserService()
        let worker = NewMessageWorker(
            userService: userService,
            keychainManager: context.keychainManager,
            userDefaultsManager: context.userDefaultsManager,
            coreDataManager: context.coreDataManager
        )
        let interactor = NewMessageInteractor(
            presenter: presenter,
            worker: worker,
            errorHandler: context.errorHandler
        )
        interactor.onRouteToChatsScreen = {
            AppCoordinator.shared.popScreen()
        }
        interactor.onRouteToNewMessageScreen = {
            AppCoordinator.shared.showNewGroupScreen()
        }
        interactor.onRouteToChat = { userData, chatData in
            AppCoordinator.shared.showChatScreen(userData, chatData)
        }
        let view = NewMessageViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
