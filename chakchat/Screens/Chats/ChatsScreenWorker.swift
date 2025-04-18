//
//  ChatsScreenWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 21.01.2025.
//

import UIKit
import OSLog

// MARK: - ChatsScreenWorker
final class ChatsScreenWorker: ChatsScreenWorkerLogic {
    
    // MARK: - Properties
    private let keychainManager: KeychainManagerBusinessLogic
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let userService: UserServiceProtocol
    private let chatsService: ChatsServiceProtocol
    private let logger: OSLog
    
    // MARK: - Initialization
    init(keychainManager: KeychainManagerBusinessLogic,
         userDefaultsManager: UserDefaultsManagerProtocol,
         userService: UserServiceProtocol,
         chatsService: ChatsServiceProtocol,
         coreDataManager: CoreDataManagerProtocol,
         logger: OSLog
    ) {
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
        self.coreDataManager = coreDataManager
        self.userService = userService
        self.chatsService = chatsService
        self.logger = logger
    }
    
    func loadMeData(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        userService.sendGetMeRequest(accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.userDefaultsManager.saveUserData(response.data)
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func loadMeRestrictions(completion: @escaping (Result<Void, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        userService.sendGetRestrictionRequest(accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.userDefaultsManager.saveRestrictions(response.data)
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func loadChats(completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatsData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        chatsService.sendGetChatsRequest(accessToken) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    self.coreDataManager.createChats(response.data)
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    
    func fetchUsers(_ name: String?, _ username: String?, _ page: Int, _ limit: Int, completion: @escaping (Result<ProfileSettingsModels.Users, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        userService.sendGetUsersRequest(name, username, page, limit, accessToken) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    self.coreDataManager.createUsers(response.data)
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    
    func getUserDataByID(_ users: [UUID], completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let myID = getMyID()
        for user in users where user != myID {
            userService.sendGetUserRequest(user, accessToken) { [weak self] result in
                guard self != nil else { return }
                switch result {
                case .success(let response):
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    
    func getDBChats() -> [ChatsModels.GeneralChatModel.ChatData]? {
        let chats = coreDataManager.fetchChats()
        let mappedChats = mapFromCoreData(chats)
        return mappedChats
    }
    
    func refreshChats(_ chats: ChatsModels.GeneralChatModel.ChatsData) {
        DispatchQueue.main.async {
            self.coreDataManager.refreshChats(chats)
        }
    }
    
    func deleteDBchats() {
        DispatchQueue.main.async {
            self.coreDataManager.deleteAllChats()
        }
    }
    
    func getMyID() -> UUID {
        let myID = userDefaultsManager.loadID()
        return myID
    }
    
    func searchForExistingChat(_ memberID: UUID) -> Chat? {
        let myID = getMyID()
        let chat = coreDataManager.fetchChatByMembers(myID, memberID, ChatType.personal)
        return chat != nil ? chat : nil
    }
    
    private func mapFromCoreData(_ chats: [Chat]) -> [ChatsModels.GeneralChatModel.ChatData]? {
        var mappedChats: [ChatsModels.GeneralChatModel.ChatData] = []
        for chatCoreData in chats {
            let decoder = JSONDecoder()
            guard let chatID = chatCoreData.chatID,
                  let typeString = chatCoreData.type,
                  let type = ChatType(rawValue: typeString),
                  let members = chatCoreData.members,
                  let createdAt = chatCoreData.createdAt,
                  let infoData = chatCoreData.info,
                  let info = (try? decoder.decode(ChatsModels.GeneralChatModel.Info.self, from: infoData))
            else { return nil }
            
            let mappedChat = ChatsModels.GeneralChatModel.ChatData(
                chatID: chatID,
                type: type,
                members: members,
                createdAt: createdAt,
                info: info
            )
            mappedChats.append(mappedChat)
        }
        return mappedChats
    }
}
