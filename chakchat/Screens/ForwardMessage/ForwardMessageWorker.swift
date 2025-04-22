//
//  ForwardMessageWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 19.04.2025.
//

import Foundation

final class ForwardMessageWorker: ForwardMessageWorkerLogic {
            
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let keychainManager: KeychainManagerBusinessLogic
    private let coreDataManager: CoreDataManagerProtocol
    private let userService: UserServiceProtocol
    private let personalUpdate: PersonalUpdateServiceProtocol
    private let groupUpdate: GroupUpdateServiceProtocol
    private let fromWhere: ChatType // чтобы понимать пересылаем из персонального или группового чата
    
    init(
        userDefaultsManager: UserDefaultsManagerProtocol,
        keychainManager: KeychainManagerBusinessLogic,
        coreDataManager: CoreDataManagerProtocol,
        userService: UserServiceProtocol,
        personalUpdate: PersonalUpdateServiceProtocol,
        groupUpdate: GroupUpdateServiceProtocol,
        fromWhere: ChatType
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.keychainManager = keychainManager
        self.coreDataManager = coreDataManager
        self.userService = userService
        self.personalUpdate = personalUpdate
        self.groupUpdate = groupUpdate
        self.fromWhere = fromWhere
    }
    
    func loadChatData() -> [ChatsModels.GeneralChatModel.ChatData] {
        let chats = coreDataManager.fetchChats()
        let mappedChats = mapFromCoreData(chats)
        return mappedChats
    }
    
    func getUserInfo(_ users: [UUID], completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let myID = userDefaultsManager.loadID()
        for user in users where user != myID {
            userService.sendGetUserRequest(user, accessToken) { result in
                switch result {
                case .success(let response):
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    
    func forwardTextMessage(_ chatFromID: UUID, _ chatToID: UUID, _ messageID: Int64, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let request = ChatsModels.UpdateModels.ForwardMessageRequest(message: messageID, fromChatID: chatFromID)
        if fromWhere == .personal {
            personalUpdate.forwardTextMessage(chatToID, request, accessToken) { result in
                switch result {
                case .success(let response):
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
        if fromWhere == .group {
            groupUpdate.forwardTextMessage(chatToID, request, accessToken) { result in
                switch result {
                case .success(let response):
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    
    func forwardFileMessage(_ chatFromID: UUID, _ chatToID: UUID, _ messageID: Int64, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let request = ChatsModels.UpdateModels.ForwardMessageRequest(message: messageID, fromChatID: chatFromID)
        if fromWhere == .personal {
            personalUpdate.forwardFileMessage(chatToID, request, accessToken) { result in
                switch result {
                case .success(let response):
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
        if fromWhere == .group {
            groupUpdate.forwardFileMessage(chatToID, request, accessToken) { result in
                switch result {
                case .success(let response):
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    
    private func mapFromCoreData(_ chats: [Chat]) -> [ChatsModels.GeneralChatModel.ChatData] {
        var mappedChats: [ChatsModels.GeneralChatModel.ChatData] = []
        for chat in chats {
            guard let chatID = chat.chatID,
                  let type = chat.type,
                  let members = chat.members,
                  let createdAt = chat.createdAt,
                  let infoData = chat.info,
                  let info = try? JSONDecoder().decode(ChatsModels.GeneralChatModel.Info.self, from: infoData)
            else { return [] }
            
            let mappedChat = ChatsModels.GeneralChatModel.ChatData(
                chatID: chatID,
                type: ChatType(rawValue: type) ?? .personal,
                members: members,
                createdAt: createdAt,
                info: info,
                updatePreview: nil
            )
            mappedChats.append(mappedChat)
        }
        return mappedChats
    }
}
