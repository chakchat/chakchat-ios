//
//  NewGroupWorker.swift
//  chakchat
//
//  Created by лизо4ка курунок on 25.02.2025.
//

import Foundation

// MARK: - NewGroupWorker
final class NewGroupWorker: NewGroupWorkerLogic {
        
    // MARK: - Properties
    private let userService: UserServiceProtocol
    private let groupChatService: GroupChatServiceProtocol
    private let fileService: FileStorageServiceProtocol
    private let keychainManager: KeychainManagerBusinessLogic
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    
    // MARK: - Initialization
    init(
        userService: UserServiceProtocol,
        groupChatService: GroupChatServiceProtocol,
        fileService: FileStorageServiceProtocol,
        keychainManager: KeychainManagerBusinessLogic,
        userDefaultsManager: UserDefaultsManagerProtocol,
        coreDataManager: CoreDataManagerProtocol
    ) {
        self.userService = userService
        self.groupChatService = groupChatService
        self.fileService = fileService
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
        self.coreDataManager = coreDataManager
    }
    
    func createGroupChat(_ name: String, _ description: String?, _ members: [UUID], completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let adminID = getMyID()
        let membersWithAdmin: [UUID] = [adminID] + members
        let request = ChatsModels.GroupChat.CreateRequest(name: name, description: description, members: membersWithAdmin)
        groupChatService.sendCreateChatRequest(request, accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.coreDataManager.createChat(response.data)
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    // MARK: - Public Methods
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
    
    func uploadGroupPhoto(_ photoID: UUID, _ chatID: UUID, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else {return}
        let request = ChatsModels.GroupChat.PhotoUpdateRequest(photoID: photoID)
        groupChatService.sendUpdatePhotoRequest(request, chatID, accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.coreDataManager.updateChat(response.data)
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func uploadImage(_ fileData: Data, _ fileName: String, _ mimeType: String, completion: @escaping (Result<SuccessModels.UploadResponse, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else {return}
        fileService.sendFileUploadRequest(fileData, fileName, mimeType, accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    private func getMyID() -> UUID {
        let myID = userDefaultsManager.loadID()
        return myID
    }
}
