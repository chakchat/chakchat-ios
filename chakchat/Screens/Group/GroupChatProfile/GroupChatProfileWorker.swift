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
    private let userService: UserServiceProtocol
    private let coreDataManager: CoreDataManagerProtocol
    
    init(
        keychainManager: KeychainManagerBusinessLogic,
        userDefaultsManager: UserDefaultsManagerProtocol,
        groupService: GroupChatServiceProtocol,
        userService: UserServiceProtocol,
        coreDataManager: CoreDataManagerProtocol
    ) {
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
        self.groupService = groupService
        self.userService = userService
        self.coreDataManager = coreDataManager
    }
    
    func deleteGroup(_ chatID: UUID, completion: @escaping (Result<EmptyResponse, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        groupService.sendDeleteChatRequest(chatID, accessToken) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func addMember(_ chatID: UUID, _ memberID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        groupService.sendAddMemberRequest(chatID, memberID, accessToken) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let response):
                // сохраняем в coreData
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func deleteMember(_ chatID: UUID, _ memberID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        groupService.sendDeleteMemberRequest(chatID, memberID, accessToken) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let response):
                // сохраняем в coreData
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
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
}
