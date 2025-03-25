//
//  SignupWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.01.2025.
//

import Foundation

// MARK: - SignupWorker
final class SignupWorker: SignupWorkerLogic {

    // MARK: - Properties
    private let keychainManager: KeychainManagerBusinessLogic
    private let userDefautlsManager: UserDefaultsManagerProtocol
    private let identityService: IdentityServiceProtocol
    private let userService: UserServiceProtocol
    
    // MARK: - Initialization
    init(
        keychainManager: KeychainManagerBusinessLogic,
        userDefautlsManager: UserDefaultsManagerProtocol,
        identityService: IdentityServiceProtocol,
        userService: UserServiceProtocol
    ) {
        self.keychainManager = keychainManager
        self.userDefautlsManager = userDefautlsManager
        self.identityService = identityService
        self.userService = userService
    }
    
    // MARK: - Public Methods
    func sendRequest(_ request: SignupModels.SignupRequest, completion: @escaping (Result<SignupState, Error>) -> Void) {
        print("Send request to service")
        identityService.sendSignupRequest(request) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {return}
                switch result {
                case .success(let successResponse):
                    self.userDefautlsManager.saveNickname(request.name)
                    self.userDefautlsManager.saveUsername(request.username)
                    self.saveToken(successResponse.data, completion: completion)
                case .failure(let apiError):
                    completion(.failure(apiError))
                }
            }
        }
    }
    
    func saveToken(_ successResponse: SuccessModels.Tokens,
                   completion: @escaping (Result<SignupState, Error>) -> Void) {
        var isSaved = self.keychainManager.save(key: KeychainManager.keyForSaveAccessToken,
                                           value: successResponse.accessToken)
        if !isSaved {
            completion(.failure(Keychain.KeychainError.saveError))
        }
        
        isSaved = self.keychainManager.save(key: KeychainManager.keyForSaveRefreshToken,
                                            value: successResponse.refreshToken)
        
        if isSaved {
            completion(.success(SignupState.onChatsMenu))
            print("Saved tokens: \nAccess:\(successResponse.accessToken)\nRefresh:\(successResponse.refreshToken)")
        } else {
            completion(.failure(Keychain.KeychainError.saveError))
        }
    }
    
    func checkUsernameAvailability(_ username: String, completion: @escaping (Result<SignupModels.UserExistsResponse, any Error>) -> Void) {
        userService.sendCheckUsernameRequest(username) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func getSignupCode() -> UUID? {
        guard let savedSignupKey = keychainManager.getUUID(key: KeychainManager.keyForSaveSignupCode) else {
            return nil
        }
        return savedSignupKey
    }
}
