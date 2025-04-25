//
//  GroupChatProfileWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import Foundation

final class GroupChatProfileWorker: GroupChatProfileWorkerLogic {
    private let keychainManager: KeychainManagerBusinessLogic
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let groupService: GroupChatServiceProtocol
    private let secretGroupService: SecretGroupChatServiceProtocol
    private let userService: UserServiceProtocol
    private let coreDataManager: CoreDataManagerProtocol
    
    init(
        keychainManager: KeychainManagerBusinessLogic,
        userDefaultsManager: UserDefaultsManagerProtocol,
        groupService: GroupChatServiceProtocol,
        secretGroupService: SecretGroupChatServiceProtocol,
        userService: UserServiceProtocol,
        coreDataManager: CoreDataManagerProtocol
    ) {
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
        self.groupService = groupService
        self.secretGroupService = secretGroupService
        self.userService = userService
        self.coreDataManager = coreDataManager
    }
    
    func createSecretGroup(_ name: String, _ description: String?, _ members: [UUID], completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let request = ChatsModels.GroupChat.CreateRequest(name: name, description: description, members: members)
        secretGroupService.sendCreateChatRequest(request, accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                DispatchQueue.main.async {
                    self.coreDataManager.createChat(response.data)
                }
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func deleteGroup(_ chatID: UUID, _ chatType: ChatType, completion: @escaping (Result<EmptyResponse, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        if chatType == .group {
            groupService.sendDeleteChatRequest(chatID, accessToken) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.coreDataManager.deleteChat(chatID)
                    }
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretGroup {
            secretGroupService.sendDeleteChatRequest(chatID, accessToken) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.coreDataManager.deleteChat(chatID)
                    }
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    
    func addMember(_ chatID: UUID, _ memberID: UUID, _ chatType: ChatType, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        if chatType == .group {
            groupService.sendAddMemberRequest(chatID, memberID, accessToken) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.coreDataManager.updateChat(response.data)
                    }
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretGroup {
            secretGroupService.sendAddMemberRequest(chatID, memberID, accessToken) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.coreDataManager.updateChat(response.data)
                    }
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    
    func deleteMember(_ chatID: UUID, _ memberID: UUID, _ chatType: ChatType, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        if chatType == .group {
            groupService.sendDeleteMemberRequest(chatID, memberID, accessToken) { [weak self] result in
                guard self != nil else { return }
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self?.coreDataManager.updateChat(response.data)
                    }
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } else if chatType == .secretGroup {
            secretGroupService.sendDeleteMemberRequest(chatID, memberID, accessToken) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.coreDataManager.updateChat(response.data)
                    }
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
            guard self != nil else { return }
            switch result {
            case .success(let users):
                completion(.success(users.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func getUserDataByID(_ users: [UUID], completion: @escaping ([ProfileSettingsModels.ProfileUserData]?) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        var result: [ProfileSettingsModels.ProfileUserData?] = Array(repeating: nil, count: users.count)
        let dispatchGroup = DispatchGroup()
        
        for (i, usr) in users.enumerated() {
            dispatchGroup.enter()
            userService.sendGetUserRequest(usr, accessToken) { [weak self] res in
                DispatchQueue.global().async {
                    defer { dispatchGroup.leave() }
                    guard self != nil else { return }
                    switch res {
                    case .success(let response):
                        result[i] = response.data
                    case .failure(_):
                        print("Failed to get data of user with id: \(usr)")
                    }
                }
            }
        }
        dispatchGroup.notify(queue: .global()) {
            let filtered = result.compactMap { $0 }
            completion(filtered.isEmpty ? nil : filtered)
        }
    }
    
    func getMyID() -> UUID {
        let myID = userDefaultsManager.loadID()
        return myID
    }
    
    func changeSecretKey(_ key: String, _ chatID: UUID) -> Bool {
        let s = keychainManager.saveSecretKey(key, chatID)
        return s
    }
}
