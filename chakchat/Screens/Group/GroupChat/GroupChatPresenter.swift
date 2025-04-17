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
}
