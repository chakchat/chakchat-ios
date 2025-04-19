//
//  AddUserAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.03.2025.
//

import UIKit

enum AddUserAssembly {
    static func build(with context: MainAppContextProtocol,
                      completion: @escaping ([ProfileSettingsModels.ProfileUserData]) -> Void) -> UIViewController {
        let presenter = AddUserPresenter()
        let userService = UserService()
        let worker = AddUserWorker(
            coreDataManager: context.coreDataManager,
            keychainManager: context.keychainManager,
            userService: userService
        )
        let interactor = AddUserInteractor(
            presenter: presenter,
            worker: worker,
            errorHandler: context.errorHandler,
            logger: context.logger
        )
        let view = AddUserViewController(interactor: interactor)
        view.onUsersSelected = completion
        presenter.view = view
        return view
    }
}
