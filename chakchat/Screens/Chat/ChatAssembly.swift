//
//  ChatAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import UIKit

// MARK: - ChatAssembly
enum ChatAssembly {
    
    static func build(_ context: MainAppContextProtocol, coordinator: AppCoordinator, userData: ProfileSettingsModels.ProfileUserData, existing: Bool) -> UIViewController {
        let presenter = ChatPresenter()
        let personalChatService = PersonalChatService()
        let updateService = UpdateService()
        let worker = ChatWorker(
            keychainManager: context.keychainManager,
            coreDataManager: context.coreDataManager,
            personalChatService: personalChatService,
            updateService: updateService
        )
        let interactor = ChatInteractor(
            presenter: presenter,
            worker: worker,
            userData: userData,
            eventPublisher: context.eventManager,
            isChatExisting: existing,
            errorHandler: context.errorHandler,
            logger: context.logger
        )
        interactor.onRouteBack = { [weak coordinator] in
            coordinator?.popScreen()
        }
        let view = ChatViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
