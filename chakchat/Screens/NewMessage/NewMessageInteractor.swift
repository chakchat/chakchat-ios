//
//  NewMessageInteractor.swift
//  chakchat
//
//  Created by лизо4ка курунок on 24.02.2025.
//

import Foundation

// MARK: - NewMessageInteractor
final class NewMessageInteractor: NewMessageBusinessLogic {
    
    // MARK: - Properties
    private let presenter: NewMessagePresentationLogic
    private let worker: NewMessageWorkerLogic
    private let errorHandler: ErrorHandlerLogic
    var onRouteToChatsScreen: (() -> Void)?
    var onRouteToNewMessageScreen: (() -> Void)?
    var onRouteToChat: ((ProfileSettingsModels.ProfileUserData, ChatsModels.GeneralChatModel.ChatData?) -> Void)?
    
    // MARK: - Initialization
    init(
        presenter: NewMessagePresentationLogic,
        worker: NewMessageWorkerLogic,
        errorHandler: ErrorHandlerLogic
    ) {
        self.presenter = presenter
        self.worker = worker
        self.errorHandler = errorHandler
    }
    
    // MARK: - Public Methods
    func fetchUsers(_ name: String?, _ username: String?, _ page: Int, _ limit: Int, completion: @escaping (Result<ProfileSettingsModels.Users, any Error>) -> Void) {
        worker.fetchUsers(name, username, page, limit) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func searchForExistingChat(_ userData: ProfileSettingsModels.ProfileUserData) {
        if let chatData = worker.searchForExistingChat(userData.id),
           let convertedChatData = mapFromCoreData(chatData) {
            routeToChat(userData, convertedChatData)
        } else {
            routeToChat(userData, nil)
        }
    }
    
    func handleError(_ error: Error) {
        _ = errorHandler.handleError(error)
    }
    
    // MARK: - Routing
    func backToChatsScreen() {
        onRouteToChatsScreen?()
    }
    
    func routeToChat(
        _ userData: ProfileSettingsModels.ProfileUserData,
        _ chatData: ChatsModels.GeneralChatModel.ChatData?
    ) {
        onRouteToChat?(userData, chatData)
    }
    
    func newGroupRoute() {
        onRouteToNewMessageScreen?()
    }
    
    private func mapFromCoreData(_ chatCoreData: Chat) -> ChatsModels.GeneralChatModel.ChatData? {
        let decoder = JSONDecoder()
        guard let chatID = chatCoreData.chatID,
              let typeString = chatCoreData.type,
              let type = ChatType(rawValue: typeString),
              let members = chatCoreData.members,
              let createdAt = chatCoreData.createdAt,
              let infoData = chatCoreData.info,
              let info = (try? decoder.decode(ChatsModels.GeneralChatModel.Info.self, from: infoData))
        else { return nil }
        
        return ChatsModels.GeneralChatModel.ChatData(
            chatID: chatID,
            type: type,
            members: members,
            createdAt: createdAt,
            info: info,
            updatePreview: nil
        )
    }
}

