//
//  ProfileSettingsWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 13.02.2025.
//

import UIKit
import Combine

// MARK: - ProfileSettingsWorker
final class ProfileSettingsWorker: ProfileSettingsScreenWorkerLogic {

    // MARK: - Properties
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let userService: UserServiceProtocol
    private let fileStorageService: FileStorageServiceProtocol
    private let identityService: IdentityServiceProtocol
    private let keychainManager: KeychainManagerBusinessLogic
    
    // MARK: - Initialization
    init(userDefaultsManager: UserDefaultsManagerProtocol,
         meService: UserServiceProtocol,
         fileStorageService: FileStorageServiceProtocol,
         identityService: IdentityServiceProtocol,
         keychainManager: KeychainManagerBusinessLogic
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.userService = meService
        self.fileStorageService = fileStorageService
        self.identityService = identityService
        self.keychainManager = keychainManager
    }
    
    // MARK: - Public Methods
    func putUserData(_ request: ProfileSettingsModels.ChangeableProfileUserData, completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        userService.sendPutMeRequest(request, accessToken) { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .success(let newUserData):
                self.userDefaultsManager.saveUserData(newUserData.data)
                completion(.success(newUserData.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func uploadImage(_ fileData: Data, _ fileName: String, _ mimeType: String, completion: @escaping (Result<SuccessModels.UploadResponse, any Error>) -> Void) {
        if let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) {
            fileStorageService.sendFileUploadRequest(fileData, fileName, mimeType, accessToken) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    self.userDefaultsManager.savePhotoMetadata(response.data)
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    
    func putProfilePhoto(_ photoID: UUID, completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let request = ProfileSettingsModels.NewPhotoRequest(photoID: photoID)
        userService.sendPutPhotoRequest(request, accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let successResponse):
                self.userDefaultsManager.saveUserData(successResponse.data)
                completion(.success(successResponse.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func deleteProfilePhoto(completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        userService.sendDeletePhotoRequest(accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.userDefaultsManager.saveUserData(response.data)
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func checkUsername(_ username: String, completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        userService.sendGetUsernameRequest(username, accessToken) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func getUserData() -> ProfileSettingsModels.ProfileUserData {
        return userDefaultsManager.loadUserData()
    }
    
    func deleteAccount(completion: @escaping (Result<SuccessResponse<EmptyResponse>, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        userService.sendDeleteMeRequest(accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                ImageCacheManager.shared.clearCache()
                if keychainManager.deleteTokens() {
                    completion(.success((response)))
                }
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
}
