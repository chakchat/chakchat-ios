//
//  ForwardMessageInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 19.04.2025.
//

import Foundation

final class ForwardMessageInteractor: ForwardMessageBusinessLogic {
    
    private let presenter: ForwardMessagePresentationLogic
    private let worker: ForwardMessageWorkerLogic
    private let chatFromID: UUID
    private let messageID: Int64
    private let forwardType: ForwardType
    
    init(
        presenter: ForwardMessagePresentationLogic,
        worker: ForwardMessageWorkerLogic,
        chatFromID: UUID,
        messageID: Int64,
        forwardType: ForwardType
    ) {
        self.presenter = presenter
        self.worker = worker
        self.chatFromID = chatFromID
        self.messageID = messageID
        self.forwardType = forwardType
    }
    
    func loadChatData() -> [ChatsModels.GeneralChatModel.ChatData] {
        return worker.loadChatData()
    }
    
    func getUserInfo(_ users: [UUID], completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, any Error>) -> Void) {
        worker.getUserInfo(users) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func forwardMessage(_ chatToID: UUID) {
        if forwardType == .text {
            forwardTextMessage(chatToID)
        }
        if forwardType == .file {
            forwardFileMessage(chatToID)
        }
    }
    
    private func forwardTextMessage(_ chatToID: UUID) {
        worker.forwardTextMessage(chatFromID, chatToID, messageID) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(_):
                    self.presenter.showForwardStatus("Successfully forward message", true)
                case .failure(_):
                    self.presenter.showForwardStatus("Failed to forward message", false)
                }
            }
        }
    }
    
    private func forwardFileMessage(_ chatToID: UUID) {
        worker.forwardFileMessage(chatFromID, chatToID, messageID) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    self.presenter.showForwardStatus("Successfully forward message", true)
                case .failure(let failure):
                    self.presenter.showForwardStatus("Failed to forward message", false)
                }
            }
        }
    }
}
