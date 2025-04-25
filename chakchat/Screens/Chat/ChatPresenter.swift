//
//  ChatPresenter.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import UIKit
import MessageKit

// MARK: - ChatPresenter
final class ChatPresenter: ChatPresentationLogic {

    
    weak var view: ChatViewController?

    func passUserData(_ chatData: ChatsModels.GeneralChatModel.ChatData? , _ userData: ProfileSettingsModels.ProfileUserData, _ isSecret: Bool, _ myID: UUID) {
        view?.configureWithData(chatData, userData, isSecret, myID)
    }
    
    func showSecretKeyFail() {
        view?.showSecretKeyFail()
    }
    
    func changeInputBar(_ isBlocked: Bool) {
        view?.changeInputBar(isBlocked)
    }
    
    func showSecretKeyAlert() {
        view?.showSecretKeyAlert()
    }
}
