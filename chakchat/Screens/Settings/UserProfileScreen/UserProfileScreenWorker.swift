//
//  UserProfileScreenWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 06.02.2025.
//

import Foundation

// MARK: - UserProfileScreenWorker
final class UserProfileScreenWorker: UserProfileScreenWorkerLogic {
    
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let identityService: IdentityServiceProtocol
    private let keychainManager: KeychainManagerBusinessLogic
    
    // MARK: - Initialization
    init(userDefaultsManager: UserDefaultsManagerProtocol, identityService: IdentityServiceProtocol, keychainManager: KeychainManagerBusinessLogic) {
        self.userDefaultsManager = userDefaultsManager
        self.identityService = identityService
        self.keychainManager = keychainManager
    }
    
    // MARK: - Public Methods
    func getUserData() -> ProfileSettingsModels.ProfileUserData {
        return userDefaultsManager.loadUserData()
    }
    
    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else {
            print("Can't load accessToken, missing probably")
            return
        }
        guard let refreshToken = keychainManager.getString(key: KeychainManager.keyForSaveRefreshToken) else {
            print("Can't load refreshToken, missing probably")
            return
        }
        let request = RefreshRequest(refreshToken: refreshToken)
        identityService.sendSignoutRequest(request, accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(_):
                ImageCacheManager.shared.clearCache()
                // если смогли удалить токены, то выходим
                if keychainManager.deleteTokens() {
                    completion(.success(()))
                }
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
}
