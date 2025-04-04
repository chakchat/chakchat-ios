//
//  PhoneVisibilityScreenWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 30.01.2025.
//

import Foundation

// MARK: - PhoneVisibilityScreenWorker
final class PhoneVisibilityScreenWorker: PhoneVisibilityScreenWorkerLogic {
    
    // MARK: - Properties
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let userService: UserServiceProtocol
    private let keychainManager: KeychainManagerBusinessLogic
    
    // MARK: - Initialization
    init(userDefaultsManager: UserDefaultsManagerProtocol,
         userService: UserServiceProtocol,
         keychainManager: KeychainManagerBusinessLogic
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.userService = userService
        self.keychainManager = keychainManager
    }
    
    // MARK: - Public Methods
    func updateUserRestriction(_ request: ConfidentialitySettingsModels.ConfidentialityUserData, completion: @escaping (Result<ConfidentialitySettingsModels.ConfidentialityUserData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        userService.sendPutRestrictionRequest(request, accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.userDefaultsManager.saveRestrictions(response.data)
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
}
