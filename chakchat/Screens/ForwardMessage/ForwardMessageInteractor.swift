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
    
    init(
        presenter: ForwardMessagePresentationLogic,
        worker: ForwardMessageWorkerLogic,
        chatFromID: UUID
    ) {
        self.presenter = presenter
        self.worker = worker
        self.chatFromID = chatFromID
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
    
    func forwardTextMessage(_ messageID: Int64, _ chatToID: UUID) {
        worker.forwardTextMessage(chatFromID, chatToID, messageID) { [weak self] result in
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
    
    func forwardFileMessage(_ messageID: Int64, _ chatToID: UUID) {
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
