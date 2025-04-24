//
//  GroupProfileEditProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit

protocol GroupProfileEditBusinessLogic {
    func passChatData()
    
    func updateChat(_ name: String, _ description: String?)
    func updateGroupPhoto(_ image: UIImage)
    
    func routeBack()
}

protocol GroupProfileEditPresentationLogic {
    func passChatData(_ chatData: GroupProfileEditModels.ProfileData)
}

protocol GroupProfileEditWorkerLogic {
    func updateChat(
        _ chatID: UUID,
        _ name: String,
        _ description: String?,
        _ chatType: ChatType,
        completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void
    )
    func updateGroupPhoto(
        _ chatID: UUID,
        _ photoID: UUID,
        _ chatType: ChatType,
        completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void
    )
    func uploadFile(_ fileData: Data,
                     _ fileName: String,
                     _ mimeType: String,
                     completion: @escaping (Result<SuccessModels.UploadResponse, Error>) -> Void)
}
