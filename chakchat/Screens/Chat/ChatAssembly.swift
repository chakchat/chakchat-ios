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
        coordinator: AppCoordinator,
        userData: ProfileSettingsModels.ProfileUserData,
        chatData: ChatsModels.GeneralChatModel.ChatData?
    ) -> UIViewController {
        
        let presenter = ChatPresenter()
        let personalChatService = PersonalChatService()
        let secretPersonalChatService = SecretPersonalChatService()
        let updateService = PersonalUpdateService()
        
        let worker = ChatWorker(
            keychainManager: context.keychainManager,
            coreDataManager: context.coreDataManager,
            personalChatService: personalChatService,
            secretPersonalChatService: secretPersonalChatService,
            updateService: updateService
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
        
        interactor.onRouteToProfile = { [weak coordinator] userData, chatData, profileConfiguration in
            coordinator?.showUserProfileScreen(userData, chatData, profileConfiguration)
        }
        interactor.onRouteBack = { [weak coordinator] in
            coordinator?.popScreen()
        }
        let view = ChatViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
