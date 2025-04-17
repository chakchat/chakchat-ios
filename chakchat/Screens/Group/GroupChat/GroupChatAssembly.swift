//
//  GroupChatAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit

enum GroupChatAssembly {
    static func build(with context: MainAppContextProtocol, coordinator: AppCoordinator, _ chatData: ChatsModels.GeneralChatModel.ChatData) -> UIViewController {
        let presenter = GroupChatPresenter()
        let updateService = UpdateService()
        let userService = UserService()
        let groupUpdateService = GroupUpdateService()
        let worker = GroupChatWorker(
            keychainManager: context.keychainManager,
            coreDataManager: context.coreDataManager,
            userDefaultsManager: context.userDefaultsManager,
            userService: userService,
            updateService: updateService,
            groupUpdateService: groupUpdateService
        )
        let interactor = GroupChatInteractor(
            presenter: presenter,
            worker: worker,
            eventSubscriber: context.eventManager,
            errorHandler: context.errorHandler,
            chatData: chatData,
            logger: context.logger
        )
        interactor.onRouteBack = { [weak coordinator] in
            coordinator?.popScreen()
        }
        interactor.onRouteToUserProfile = { [weak coordinator] user, chatData, profileConfiguration in
            coordinator?.showUserProfileScreen(user, chatData, profileConfiguration)
        }
        interactor.onRouteToGroupProfile = { [weak coordinator] chatData in
            coordinator?.showGroupChatProfile(chatData)
        }
        interactor.onRouteToMyProfile = { [weak coordinator] in
            coordinator?.showUserSettingsScreen()
        }
        let view = GroupChatViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
