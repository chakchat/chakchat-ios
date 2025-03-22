//
//  ProfileSettingsInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.01.2025.
//

import UIKit
import OSLog
import Combine

// MARK: - ProfileSettingsInteractor
final class ProfileSettingsInteractor: ProfileSettingsScreenBusinessLogic {
    
    // MARK: - Properties
    private let presenter: ProfileSettingsScreenPresentationLogic
    private let worker: ProfileSettingsScreenWorkerLogic
    private let eventPublisher: EventPublisherProtocol
    private let errorHandler: ErrorHandlerLogic
    private let logger: OSLog
    
    var onRouteToSettingsMenu: (() -> Void)?
    var onRouteToRegistration: (() -> Void)?
    
    // MARK: - Initialization
    init(presenter: ProfileSettingsScreenPresentationLogic,
         worker: ProfileSettingsScreenWorkerLogic,
         eventPublisher: EventPublisherProtocol,
         errorHandler: ErrorHandlerLogic,
         logger: OSLog
    ) {
        self.presenter = presenter
        self.worker = worker
        self.eventPublisher = eventPublisher
        self.errorHandler = errorHandler
        self.logger = logger
    }
    

    // MARK: - Public Methods
    func loadUserData() {
        os_log("Loaded user data in profile settings screen", log: logger, type: .default)
        let userData = worker.getUserData()
        showUserData(userData)
    }
    
    func showUserData(_ userData: ProfileSettingsModels.ProfileUserData) {
        os_log("Passed user data in settigns screen to presenter", log: logger, type: .default)
        presenter.showUserData(userData)
    }

    func putNewData(_ newUserData: ProfileSettingsModels.ChangeableProfileUserData) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.worker.putUserData(newUserData) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else {return}
                    switch result {
                    case .success(_):
                        os_log("Uploading user data complete", log: self.logger, type: .info)
                        let updateProfileDataEvent = UpdateProfileDataEvent(
                            newNickname: newUserData.name,
                            newUsername: newUserData.username,
                            newBirth: newUserData.dateOfBirth
                        )
                        os_log("Published event in profile settings screen", log: self.logger, type: .default)
                        self.eventPublisher.publish(event: updateProfileDataEvent)
                    case .failure(let failure):
                        _ = self.errorHandler.handleError(failure)
                        os_log("Uploading user data failed:\n", log: self.logger, type: .fault)
                        print(failure)
                    }
                }
            }
        }
        DispatchQueue.main.async {
            self.onRouteToSettingsMenu?()
        }
    }
    
    func putProfilePhoto(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        uploadFile(image) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                os_log("Uploaded user photo to file storage", log: logger, type: .default)
                worker.putProfilePhoto(data.fileId) { result in
                    switch result {
                    case .success(let data):
                        os_log("Uploaded user photo", log: self.logger, type: .default)
                        let updatePhotoEvent = UpdatePhotoEvent(newPhoto: data.photo)
                        self.eventPublisher.publish(event: updatePhotoEvent)
                        completion(.success(()))
                    case .failure(let failure):
                        _ = self.errorHandler.handleError(failure)
                        os_log("Failed to upload user photo", log: self.logger, type: .fault)
                        print(failure)
                        completion(.failure(failure))
                    }
                }
            case .failure(let failure):
                _ = errorHandler.handleError(failure)
                os_log("Failed to upload user photo to file storage", log: logger, type: .fault)
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
    
    
    func deleteProfilePhoto() {
        worker.deleteProfilePhoto() { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(_):
                    let updatePhotoEvent = UpdatePhotoEvent(newPhoto: nil)
                    self.eventPublisher.publish(event: updatePhotoEvent)
                    self.presenter.deleteImage()
                case .failure(let failure):
                    _ = self.errorHandler.handleError(failure)
                    os_log("Failed to delete photo:\n", log: self.logger, type: .fault)
                    print(failure)
                }
            }
        }
    }
    
    func checkUsername(_ username: String, completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, any Error>) -> Void) {
        worker.checkUsername(username) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                os_log("Checking for username completed", log: logger, type: .default)
                completion(.success(data))
            case .failure(let failure):
                os_log("Checking for username failed:\n", log: logger, type: .fault)
                _ = errorHandler.handleError(failure)
                print(failure)
                completion(.failure(failure))
            }
        }
    }
    
    func signOut() {
        worker.signOut { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(_):
                os_log("Signout from account, data deleted", log: logger, type: .info)
                backToRegistration()
            case .failure(let failure):
                _ = self.errorHandler.handleError(failure)
                os_log("Failed to signout:\n", log: logger, type: .fault)
                print(failure)
            }
        }
    }
    
    
    // MARK: - Routing
    func backToSettingsMenu() {
        os_log("Routed to settings menu screen", log: logger, type: .default)
        onRouteToSettingsMenu?()
    }
    
    func backToRegistration() {
        os_log("Routed to registration", log: logger, type: .default)
        DispatchQueue.main.async {
            self.onRouteToRegistration?()
        }
    }
}
