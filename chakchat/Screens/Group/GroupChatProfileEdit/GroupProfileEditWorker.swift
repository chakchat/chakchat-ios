//
//  GroupProfileEditWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit

final class GroupProfileEditWorker: GroupProfileEditWorkerLogic {
    private let keychainManager: KeychainManagerBusinessLogic
    private let groupService: GroupChatServiceProtocol
    private let secretGroupService: SecretGroupChatServiceProtocol
    private let fileStorageService: FileStorageServiceProtocol
    private let coreDataManager: CoreDataManagerProtocol
    
    init(
        keychainManager: KeychainManagerBusinessLogic,
        groupService: GroupChatServiceProtocol,
        secretGroupService: SecretGroupChatServiceProtocol,
        fileStorageService: FileStorageServiceProtocol,
        coreDataManager: CoreDataManagerProtocol
    ) {
        self.keychainManager = keychainManager
        self.groupService = groupService
        self.secretGroupService = secretGroupService
        self.fileStorageService = fileStorageService
        self.coreDataManager = coreDataManager
    }
    
    func updateChat(_ chatID: UUID, _ name: String, _ description: String?, _ chatType: ChatType, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        if chatType == .group {
            let request = ChatsModels.GroupChat.UpdateRequest(name: name, description: description)
            groupService.sendUpdateChatRequest(chatID, request, accessToken) { [weak self] result in
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
            let request = ChatsModels.GroupChat.UpdateRequest(name: name, description: description)
            secretGroupService.sendUpdateChatRequest(chatID, request, accessToken) { [weak self] result in
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
    
    func updateGroupPhoto(_ chatID: UUID, _ photoID: UUID, _ chatType: ChatType, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        if chatType == .group {
            let request = ChatsModels.GroupChat.PhotoUpdateRequest(photoID: photoID)
            groupService.sendUpdatePhotoRequest(request, chatID, accessToken) { [weak self] result in
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
            let request = ChatsModels.GroupChat.PhotoUpdateRequest(photoID: photoID)
            secretGroupService.sendUpdatePhotoRequest(request, chatID, accessToken) { [weak self] result in
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
    
    
    func uploadFile(_ fileData: Data, _ fileName: String, _ mimeType: String, completion: @escaping (Result<SuccessModels.UploadResponse, any Error>) -> Void) {
        if let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) {
            fileStorageService.sendFileUploadRequest(fileData, fileName, mimeType, accessToken) { [weak self] result in
                guard self != nil else { return }
                switch result {
                case .success(let response):
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
}
