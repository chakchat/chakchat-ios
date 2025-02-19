//
//  ProfileSettingsWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 13.02.2025.
//

import Foundation

final class ProfileSettingsWorker: ProfileSettingsScreenWorkerLogic {

    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let meService: MeServiceProtocol
    private let fileStorageService: FileStorageServiceProtocol
    private let identityService: IdentityServiceProtocol
    private let keychainManager: KeychainManagerBusinessLogic
    
    init(userDefaultsManager: UserDefaultsManagerProtocol,
         meService: MeServiceProtocol,
         fileStorageService: FileStorageServiceProtocol,
         identityService: IdentityServiceProtocol,
         keychainManager: KeychainManagerBusinessLogic
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.meService = meService
        self.fileStorageService = fileStorageService
        self.identityService = identityService
        self.keychainManager = keychainManager
    }
    
    func updateUserData(_ request: ProfileSettingsModels.ChangeableProfileUserData, completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, any Error>) -> Void) {
        meService.sendPutMeRequest(request) { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .success(let newUserData):
                self.userDefaultsManager.saveUserData(newUserData)
                completion(.success(newUserData))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func saveImageURL(_ url: URL) {
        userDefaultsManager.savePhotoURL(url)
    }
    
    func uploadImage(_ fileURL: URL, _ fileName: String, _ mimeType: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        if let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) {
            fileStorageService.sendFileUploadRequest(fileURL, fileName, mimeType, accessToken) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    self.userDefaultsManager.savePhotoMetadata(data)
                    completion(.success(()))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    /// уже объяснял в файле IdentityService почему я использую здесь
    /// реквест типа RefreshRequest. Ручки "refresh-token" и "sing-out" имеют одинаковый
    /// формат request'a, поэтому использую один для двоих
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
            case .success(let success):
                // если смогли удалить токены, то выходим
                if keychainManager.deleteTokens() {
                    completion(.success(()))
                }
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func getUserData() -> ProfileSettingsModels.ProfileUserData {
        return userDefaultsManager.loadUserData()
    }
    
}
