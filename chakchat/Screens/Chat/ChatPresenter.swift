//
//  ChatPresenter.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import UIKit

// MARK: - ChatPresenter
final class ChatPresenter: ChatPresentationLogic {

    
    weak var view: ChatViewController?

    func passUserData(_ userData: ProfileSettingsModels.ProfileUserData, _ isSecret: Bool) {
        view?.configureWithData(userData, isSecret)
    }
    
    func showSecretKeyFail() {
        view?.showSecretKeyFail()
    }
}
