//
//  ChatAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import UIKit

// MARK: - ChatAssembly
enum ChatAssembly {
    
    static func build(
        _ context: MainAppContextProtocol,
        userData: ProfileSettingsModels.ProfileUserData,
        chatData: ChatsModels.GeneralChatModel.ChatData?
    ) -> UIViewController {
        
        let presenter = ChatPresenter()
        let personalChatService = PersonalChatService()
        let secretPersonalChatService = SecretPersonalChatService()
        let updateService = UpdateService()
        let personalUpdateService = PersonalUpdateService()
        
        let worker = ChatWorker(
            keychainManager: context.keychainManager,
            userDefaultsManager: context.userDefaultsManager,
            coreDataManager: context.coreDataManager,
            personalChatService: personalChatService,
            secretPersonalChatService: secretPersonalChatService,
            updateService: updateService,
            personalUpdateService: personalUpdateService
        )
        
        let interactor = ChatInteractor(
            presenter: presenter,
            worker: worker,
            userData: userData,
            eventManager: context.eventManager,
            errorHandler: context.errorHandler,
            logger: context.logger,
            chatData: chatData
        )
        
        interactor.onRouteToProfile = { userData, chatData, profileConfiguration in
            AppCoordinator.shared.showUserProfileScreen(userData, chatData, profileConfiguration)
        }
        interactor.onRouteBack = {
            AppCoordinator.shared.popScreen()
        }
        let view = ChatViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
