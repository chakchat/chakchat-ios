//
//  ChatsScreenAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 21.01.2025.
//

import Foundation
import UIKit

// MARK: - ChatAssembly
enum ChatsAssembly {
    
    static func build(with context: MainAppContextProtocol) -> UIViewController {
        let presenter = ChatsScreenPresenter()
        let userService = UserService()
        let chatsService = ChatsService()
        let worker = ChatsScreenWorker(
            keychainManager: context.keychainManager,
            userDefaultsManager: context.userDefaultsManager,
            userService: userService,
            chatsService: chatsService,
            coreDataManager: context.coreDataManager,
            logger: context.logger
        )
        let interactor = ChatsScreenInteractor(
            presenter: presenter,
            worker: worker,
            logger: context.logger,
            errorHandler: context.errorHandler,
            eventSubscriber: context.eventManager,
            keychainManager: context.keychainManager
        )
        interactor.onRouteToChat = { userData, chatData in
            AppCoordinator.shared.showChatScreen(userData, chatData)
        }
        interactor.onRouteToGroupChat = { chatData in
            AppCoordinator.shared.showGroupChatScreen(chatData)
        }
        interactor.onRouteToSettings = {
            AppCoordinator.shared.showSettingsScreen()
        }
        interactor.onRouteToNewMessage = {
            AppCoordinator.shared.showNewMessageScreen()
        }
        
        let view = ChatsScreenViewController(interactor: interactor)
        presenter.view = view
        
        return view
    }
}
