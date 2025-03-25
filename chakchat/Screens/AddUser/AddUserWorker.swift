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
        guard let uuids = coreDataManager.fetchUsers(),
              let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else {
            completion(nil)
            return
        }
        
        var results: [ProfileSettingsModels.ProfileUserData?] = Array(repeating: nil, count: uuids.count)
        let dispatchGroup = DispatchGroup()
        
        for (i,uuid) in uuids.enumerated() {
            dispatchGroup.enter()
            userService.sendGetUserRequest(uuid, accessToken) { result in
                DispatchQueue.global().async {
                    defer { dispatchGroup.leave() }
                    switch result {
                    case .success(let response):
                        results[i] = response.data
                    case .failure(_):
                        print("Failed to get data of user with id: \(uuid)")
                    }
                }
            }
        }
        dispatchGroup.notify(queue: .global()) {
            let filtered = results.compactMap { $0 }
            completion(filtered.isEmpty ? nil : filtered)
        }
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
    
}
