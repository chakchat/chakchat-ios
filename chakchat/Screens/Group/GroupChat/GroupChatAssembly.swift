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
        let worker = GroupChatWorker(
            keychainManager: context.keychainManager,
            coreDataManager: context.coreDataManager,
            updateService: updateService
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
        interactor.onRouteToGroupProfile = { [weak coordinator] chatData in
            coordinator?.showGroupChatProfile(chatData)
        }
        let view = GroupChatViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
