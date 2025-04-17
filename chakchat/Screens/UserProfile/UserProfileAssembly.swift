//
//  UserProfileAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import UIKit

// MARK: - UserProfileAssembly
enum UserProfileAssembly {
    
    static func build(
        _ context: MainAppContextProtocol,
        userData: ProfileSettingsModels.ProfileUserData,
        chatData: ChatsModels.GeneralChatModel.ChatData?,
        profileConfiguration: ProfileConfiguration
    ) -> UIViewController {
        let presenter = UserProfilePresenter()
        let updateService = PersonalUpdateService()
        let personalChatService = PersonalChatService()
        let secretPersonalChatService = SecretPersonalChatService()
        let worker = UserProfileWorker(
            userDefaultsManager: context.userDefaultsManager,
            keychainManager: context.keychainManager,
            coreDataManager: context.coreDataManager,
            personalChatService: personalChatService, 
            secretPersonalChatService: secretPersonalChatService,
            messagingService: updateService
        )
        let interactor = UserProfileInteractor(
            presenter: presenter,
            worker: worker,
            errorHandler: context.errorHandler,
            eventPublisher: context.eventManager,
            userData: userData,
            chatData: chatData,
            profileConfiguration: profileConfiguration,
            logger: context.logger
        )
        interactor.onRouteBack = {
            AppCoordinator.shared.popScreen()
        }
        interactor.onRouteToChat = { userData, chatData in
            AppCoordinator.shared.showChatScreen(userData, chatData)
        }
        interactor.onRouteToMain = {
            AppCoordinator.shared.setChatsScreen()
        }
        let view = UserProfileViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
