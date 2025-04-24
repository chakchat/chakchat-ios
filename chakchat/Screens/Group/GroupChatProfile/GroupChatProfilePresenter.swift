//
//  GroupChatProfilePresenter.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit

final class GroupChatProfilePresenter: GroupChatProfilePresentationLogic {
    weak var view: GroupChatProfileViewController?
    
    func passChatData(_ chatData: ChatsModels.GeneralChatModel.ChatData, _ isAdmin: Bool) {
        view?.configureWithUserData(chatData, isAdmin)
    }
    
    func updateGroupInfo(_ name: String, _ description: String?) {
        view?.updateGroupInfo(name, description)
    }
    
    func updateGroupPhoto(_ image: UIImage?) {
        view?.updateGroupPhoto(image)
    }
    
    func showFailDisclaimer() {
        view?.showFailDisclaimer()
    }
}
