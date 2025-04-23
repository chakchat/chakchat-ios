//
//  GroupChatPresenter.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit

final class GroupChatPresenter: GroupChatPresentationLogic {
    
    weak var view: GroupChatViewController?
    
    func passChatData(_ chatData: ChatsModels.GeneralChatModel.ChatData, _ myID: UUID) {
        view?.configureWithData(chatData, myID)
    }
    
    func updateGroupPhoto(_ image: UIImage?) {
        view?.updateGroupPhoto(image)
    }
    
    func updateGroupInfo(_ name: String, _ description: String?) {
        view?.updateGroupInfo(name, description)
    }
    
    func showInputSecretKeyAlert() {
        view?.showInputSecretKeyAlert()
    }
}
