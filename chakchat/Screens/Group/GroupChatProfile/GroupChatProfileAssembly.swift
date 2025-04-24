//
//  GroupChatProfileAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit

enum GroupChatProfileAssembly {
    static func build(with context: MainAppContextProtocol, _ chatData: ChatsModels.GeneralChatModel.ChatData) -> UIViewController {
        let presenter = GroupChatProfilePresenter()
        let groupService = GroupChatService()
        let userService = UserService()
        let secretGroupService = SecretGroupChatService()
        let worker = GroupChatProfileWorker(
            keychainManager: context.keychainManager, 
            userDefaultsManager: context.userDefaultsManager,
            groupService: groupService,
            secretGroupService: secretGroupService,
            userService: userService,
            coreDataManager: context.coreDataManager
        )
        let interactor = GroupChatProfileInteractor(
            presenter: presenter,
            worker: worker,
            errorHandler: context.errorHandler,
            chatData: chatData,
            eventManager: context.eventManager,
            logger: context.logger
        )
        interactor.onRouteToEdit = { chatData in
            AppCoordinator.shared.showGroupProfileEditScreen(chatData)
        }
        interactor.onRouteToChatMenu = {
            AppCoordinator.shared.setChatsScreen()
        }
        interactor.onRouteBack = {
            AppCoordinator.shared.popScreen()
        }
        interactor.onRouteToProfile = { userData, conf in
            AppCoordinator.shared.showUserProfileScreen(userData, nil, conf)
        }
        interactor.onRouteToMyProfile = {
            AppCoordinator.shared.showUserSettingsScreen()
        }
        interactor.onRouteToSecretChat = { chatData in
            AppCoordinator.shared.showGroupChatScreen(chatData)
        }
        let view = GroupChatProfileViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
