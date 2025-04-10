//
//  AddUserWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.03.2025.
//

import Foundation

final class AddUserWorker: AddUserWorkerLogic {
    
    private let coreDataManager: CoreDataManagerProtocol
    private let keychainManager: KeychainManagerBusinessLogic
    private let userService: UserServiceProtocol
    
    init(
        coreDataManager: CoreDataManagerProtocol,
        keychainManager: KeychainManagerBusinessLogic,
        userService: UserServiceProtocol
    ) {
        self.coreDataManager = coreDataManager
        self.keychainManager = keychainManager
        self.userService = userService
    }
    
    func loadUsers(completion: @escaping ([ProfileSettingsModels.ProfileUserData]?) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else {
            completion(nil)
            return
        }
        let users = coreDataManager.fetchUsers()
        let mappedUsers = mapFromCoreData(users)
        completion(mappedUsers)
    }
    
    func fetchUsers(_ name: String?, _ username: String?, _ offset: Int, _ limit: Int, completion: @escaping (Result<ProfileSettingsModels.Users, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        userService.sendGetUsersRequest(name, username, offset, limit, accessToken) { result in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    private func mapFromCoreData(_ users: [User]) -> [ProfileSettingsModels.ProfileUserData]? {
        var mappedUsers: [ProfileSettingsModels.ProfileUserData] = []
        for user in users {
            guard let id = user.id,
                  let name = user.name,
                  let username = user.username,
                  let createdAt = user.createdAt else {
                debugPrint("Cant map from coredata in AddUserWorker")
                return nil
            }
            
            let mappedUser = ProfileSettingsModels.ProfileUserData(
                id: id,
                name: name,
                username: username,
                phone: user.phone ?? nil,
                photo: user.photo ?? nil,
                dateOfBirth: user.dateOfBirth ?? nil,
                createdAt: createdAt
            )
            mappedUsers.append(mappedUser)
        }
        return mappedUsers
    }
}
