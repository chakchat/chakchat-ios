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
        let secretPersonalUpdateService = SecretPersonalUpdateService()
        let fileService = FileStorageService()
        
        let worker = ChatWorker(
            keychainManager: context.keychainManager,
            userDefaultsManager: context.userDefaultsManager,
            coreDataManager: context.coreDataManager,
            personalChatService: personalChatService,
            secretPersonalChatService: secretPersonalChatService,
            updateService: updateService,
            fileService: fileService,
            personalUpdateService: personalUpdateService,
            secretPersonalUpdateService: secretPersonalUpdateService
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
        interactor.onPresentForwardVC = { chatID, messageID, forwardType, chatType in
            AppCoordinator.shared.showForwardScreen(chatID, messageID, forwardType, chatType)
        }
        let view = ChatViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
