//
//  ForwardMessageProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 19.04.2025.
//

import Foundation

protocol ForwardMessageBusinessLogic {
    func loadChatData() -> [ChatsModels.GeneralChatModel.ChatData]
    
    func getUserInfo(_ users: [UUID], completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, Error>) -> Void)
    
    func forwardTextMessage(_ messageID: Int64, _ chatToID: UUID)
    func forwardFileMessage(_ messageID: Int64, _ chatToID: UUID)
}

protocol ForwardMessageWorkerLogic {
    func loadChatData() -> [ChatsModels.GeneralChatModel.ChatData]
    
    func getUserInfo(_ users: [UUID], completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, Error>) -> Void)
    
    func forwardTextMessage(_ chatFromID: UUID, _ chatToID: UUID, _ messageID: Int64, completion: @escaping (Result<UpdateData, Error>) -> Void)
    
    func forwardFileMessage(_ chatFromID: UUID, _ chatToID: UUID, _ messageID: Int64, completion: @escaping (Result<UpdateData, Error>) -> Void)
}

protocol ForwardMessagePresentationLogic {
    func showForwardStatus(_ message: String, _ status: Bool)
}
