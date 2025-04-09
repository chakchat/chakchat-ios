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
    
    func presentMessage(_ message: ChatModels.Message) {
        let m = mapToMessageKit(message)
        DispatchQueue.main.async {
            self.view?.displayNewMessage(m)
        }
    }
    
    func updateMessageStatus(_ id: String, _ newMessage: ChatModels.Message) {
        let m = mapToMessageKit(newMessage)
        DispatchQueue.main.async {
            self.view?.updateMessage(id, m)
        }
    }
    
    func updateMessageStatus(_ id: String) {
        DispatchQueue.main.async {
            self.view?.markMessageAsFailed(id)
        }
    }
    // имя неважно в персональных чатах
    private func mapToMessageKit(_ message: ChatModels.Message) -> MessageForKit {
        let m = MessageForKit(
            sender: SenderPerson(senderId: message.senderID.uuidString, displayName: ""),
            messageId: message.updateID,
            sentDate: message.sentAt,
            kind: .text(message.text),
            status: message.status
        )
        return m
    }
}
