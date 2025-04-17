//
//  NewGroupAssembly.swift
//  chakchat
//
//  Created by лизо4ка курунок on 25.02.2025.
//

import UIKit

// MARK: - NewGroupAssembly
enum NewGroupAssembly {
    
    static func build(with context: MainAppContextProtocol) -> UIViewController {
        let presenter = NewGroupPresenter()
        let userService = UserService()
        let groupChatService = GroupChatService()
        let fileService = FileStorageService()
        let worker = NewGroupWorker(
            userService: userService,
            groupChatService: groupChatService,
            fileService: fileService,
            keychainManager: context.keychainManager,
            userDefaultsManager: context.userDefaultsManager,
            coreDataManager: context.coreDataManager
        )
        let interactor = NewGroupInteractor(
            presenter: presenter,
            worker: worker,
            logger: context.logger,
            errorHandler: context.errorHandler, 
            eventPublisher: context.eventManager
        )
        interactor.onRouteToGroupChat = { chatData in
            AppCoordinator.shared.showGroupChatScreen(chatData)
        }
        
        interactor.onRouteToNewMessageScreen = {
            AppCoordinator.shared.popScreen()
        }
        let view = NewGroupViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}

