//
//  GroupChatAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit

enum GroupChatAssembly {
    static func build(with context: MainAppContextProtocol, _ chatData: ChatsModels.GeneralChatModel.ChatData) -> UIViewController {
        let presenter = GroupChatPresenter()
        let updateService = UpdateService()
        let userService = UserService()
        let groupUpdateService = GroupUpdateService()
        let fileService = FileStorageService()
        let worker = GroupChatWorker(
            keychainManager: context.keychainManager,
            coreDataManager: context.coreDataManager,
            userDefaultsManager: context.userDefaultsManager,
            userService: userService,
            updateService: updateService,
            fileService: fileService,
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
        interactor.onRouteBack = {
            AppCoordinator.shared.popScreen()
        }
        interactor.onRouteToUserProfile = { user, chatData, profileConfiguration in
            AppCoordinator.shared.showUserProfileScreen(user, chatData, profileConfiguration)
        }
        interactor.onRouteToGroupProfile = { chatData in
            AppCoordinator.shared.showGroupChatProfile(chatData)
        }
        interactor.onRouteToMyProfile = {
            AppCoordinator.shared.showUserSettingsScreen()
        }
        interactor.onPresentForwardVC = { chatID, messageID, forwardType, chatType in
            AppCoordinator.shared.showForwardScreen(chatID, messageID, forwardType, chatType)
        }
        let view = GroupChatViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
