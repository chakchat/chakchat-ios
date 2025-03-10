//
//  NewGroupAssembly.swift
//  chakchat
//
//  Created by лизо4ка курунок on 25.02.2025.
//

import UIKit

// MARK: - NewGroupAssembly
enum NewGroupAssembly {
    
    static func build(with context: MainAppContextProtocol, coordinator: AppCoordinator) -> UIViewController {
        let presenter = NewGroupPresenter()
        let userService = UserService()
        let groupChatService = GroupChatService()
        let worker = NewGroupWorker(
            userService: userService,
            groupChatService: groupChatService,
            keychainManager: context.keychainManager,
            userDefaultsManager: context.userDefaultsManager,
            coreDataManager: context.coreDataManager
        )
        let interactor = NewGroupInteractor(
            presenter: presenter,
            worker: worker,
            logger: context.logger,
            errorHandler: context.errorHandler
        )
        interactor.onRouteToGroupChat = { [weak coordinator] chatData in
            coordinator?.showGroupChatScreen(chatData)
        }
        
        interactor.onRouteToNewMessageScreen = { [weak coordinator] in
            coordinator?.popScreen()
        }
        let view = NewGroupViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}

