//
//  GroupChatProfileAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit

enum GroupChatProfileAssembly {
    static func build(with context: MainAppContextProtocol, coordinator: AppCoordinator, _ chatData: ChatsModels.GroupChat.Response) -> UIViewController {
        let presenter = GroupChatProfilePresenter()
        let groupService = GroupChatService()
        let worker = GroupChatProfileWorker(
            keychainManager: context.keychainManager, 
            userDefaultsManager: context.userDefaultsManager,
            groupService: groupService,
            coreDataManager: context.coreDataManager
        )
        let interactor = GroupChatProfileInteractor(
            presenter: presenter,
            worker: worker,
            errorHandler: context.errorHandler,
            chatData: chatData,
            eventPublisher: context.eventManager,
            logger: context.logger
        )
        interactor.onRouteToEdit = { [weak coordinator] chatData in
            coordinator?.showGroupProfileEditScreen(chatData)
        }
        // интересно как это будет выглядеть
        interactor.onRouteToChatMenu = { [weak coordinator] in
            coordinator?.popScreen()
            coordinator?.popScreen()
        }
        interactor.onRouteBack = { [weak coordinator] in
            coordinator?.popScreen()
        }
        let view = GroupChatProfileViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
