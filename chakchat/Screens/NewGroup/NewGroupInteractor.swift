//
//  NewGroupInteractor.swift
//  chakchat
//
//  Created by лизо4ка курунок on 25.02.2025.
//

import UIKit
import OSLog

// MARK: - NewGroupInteractor
final class NewGroupInteractor: NewGroupBusinessLogic {
        
    // MARK: - Properties
    private let presenter: NewGroupPresentationLogic
    private let worker: NewGroupWorkerLogic
    private let errorHandler: ErrorHandlerLogic
    private let eventPublisher: EventPublisherProtocol
    private let logger: OSLog
    var onRouteToGroupChat: ((ChatsModels.GeneralChatModel.ChatData) -> Void)?
    var onRouteToNewMessageScreen: (() -> Void)?
    
    // MARK: - Initialization
    init(
        presenter: NewGroupPresentationLogic,
        worker: NewGroupWorkerLogic,
        logger: OSLog,
        errorHandler: ErrorHandlerLogic,
        eventPublisher: EventPublisherProtocol
    ) {
        self.presenter = presenter
        self.worker = worker
        self.logger = logger
        self.errorHandler = errorHandler
        self.eventPublisher = eventPublisher
    }
    
    func createGroupChat(_ name: String, _ description: String?, _ members: [UUID], _ image: UIImage?) {
        worker.createGroupChat(name, description, members) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    if let image {
                        self.uploadGroupPhoto(image, data.chatID)
                        let event = CreatedChatEvent(
                            chatID: data.chatID,
                            type: data.type,
                            members: data.members,
                            createdAt: data.createdAt,
                            info: data.info
                        )
                        self.eventPublisher.publish(event: event)
                    } else {
                        let event = CreatedChatEvent(
                            chatID: data.chatID,
                            type: data.type,
                            members: data.members,
                            createdAt: data.createdAt,
                            info: data.info
                        )
                        self.eventPublisher.publish(event: event)
                        self.routeToGroupChat(data)
                    }
                case .failure(let failure):
                    _ = self.errorHandler.handleError(failure)
                    os_log("Failed to create group chat", log: self.logger, type: .fault)
                    print(failure)
                }
            }
        }
    }

    func fetchUsers(_ name: String?, _ username: String?, _ page: Int, _ limit: Int, completion: @escaping (Result<ProfileSettingsModels.Users, any Error>) -> Void) {
        worker.fetchUsers(name, username, page, limit) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func uploadGroupPhoto(_ image: UIImage, _ chatID: UUID) {
        uploadFile(image) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let d):
                worker.uploadGroupPhoto(d.fileId, chatID) { res in
                    DispatchQueue.main.async {
                        switch res {
                        case .success(let data):
                            ImageCacheManager.shared.saveImage(image, for: d.fileURL as NSURL)
                            self.routeToGroupChat(data)
                            let event = UpdatedGroupPhotoEvent(photo: image)
                            self.eventPublisher.publish(event: event)
                        case .failure(let failure):
                            _ = self.errorHandler.handleError(failure)
                            os_log("Failed to upload group chat photo", log: self.logger, type: .fault)
                            print(failure)
                        }
                    }
                }
            case .failure(let failure):
                _ = self.errorHandler.handleError(failure)
                os_log("Failed to upload group chat photo to storage", log: self.logger, type: .fault)
                print(failure)
            }
        }
    }
    
    func uploadFile(_ image: UIImage, completion: @escaping (Result<SuccessModels.UploadResponse, any Error>) -> Void) {
        os_log("Started saving image in profile setting screen", log: logger, type: .default)
        guard let data = image.jpegData(compressionQuality: 0.0) else {
            return
        }
        let fileName = "\(UUID().uuidString).jpeg"
        worker.uploadImage(data, fileName, "image/jpeg") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let fileMetaData):
                ImageCacheManager.shared.saveImage(image, for: fileMetaData.fileURL as NSURL)
                completion(.success(fileMetaData))
            case .failure(let failure):
                _ = errorHandler.handleError(failure)
                os_log("Uploading user image failed:\n", log: logger, type: .fault)
                print(failure)
            }
        }
    }
    
    func handleError(_ error: Error) {
        _ = errorHandler.handleError(error)
    }
    // MARK: - Routing
    func routeToGroupChat(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        onRouteToGroupChat?(chatData)
    }
    
    func backToNewMessageScreen() {
        onRouteToNewMessageScreen?()
    }
}


