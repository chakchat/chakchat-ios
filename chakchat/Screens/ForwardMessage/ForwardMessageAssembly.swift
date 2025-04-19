//
//  ForwardMessageAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 19.04.2025.
//

import UIKit

enum ForwardMessageAssembly {
    static func build(
        with context: MainAppContextProtocol,
        _ chatFromID: UUID,
        _ messageID: Int64,
        _ forwardType: ForwardType,
        _ chatType: ChatType
    ) -> UIViewController {
        let presenter = ForwardMessagePresenter()
        let userService = UserService()
        let personalUpdate = PersonalUpdateService()
        let groupUpdate = GroupUpdateService()
        
        let worker = ForwardMessageWorker(
            userDefaultsManager: context.userDefaultsManager,
            keychainManager: context.keychainManager,
            coreDataManager: context.coreDataManager,
            userService: userService,
            personalUpdate: personalUpdate,
            groupUpdate: groupUpdate,
            fromWhere: chatType
        )
        
        let interactor = ForwardMessageInteractor(
            presenter: presenter,
            worker: worker,
            chatFromID: chatFromID,
            messageID: messageID,
            forwardType: forwardType
        )
        
        let view = ForwardMessageViewController(interactor: interactor)
        
        presenter.view = view
        return view
    }
}
