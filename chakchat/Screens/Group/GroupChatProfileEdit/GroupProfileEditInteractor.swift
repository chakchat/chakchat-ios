//
//  GroupProfileEditInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit
import OSLog

final class GroupProfileEditInteractor: GroupProfileEditBusinessLogic {
    private let presenter: GroupProfileEditPresentationLogic
    private let worker: GroupProfileEditWorkerLogic
    private let errorHandler: ErrorHandlerLogic
    private let eventPublisher: EventPublisherProtocol
    private let chatData: GroupProfileEditModels.ProfileData
    private let logger: OSLog
    
    var onRouteBack: (() -> Void)?
    
    init(
        presenter: GroupProfileEditPresentationLogic,
        worker: GroupProfileEditWorkerLogic,
        errorHandler: ErrorHandlerLogic,
        eventPublisher: EventPublisherProtocol,
        chatData: GroupProfileEditModels.ProfileData,
        logger: OSLog
    ) {
        self.presenter = presenter
        self.worker = worker
        self.errorHandler = errorHandler
        self.eventPublisher = eventPublisher
        self.chatData = chatData
        self.logger = logger
    }
    
    func passChatData() {
        presenter.passChatData(chatData)
    }
    
    func updateChat(_ name: String, _ description: String?) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.worker.updateChat(self.chatData.chatID, name, description, self.chatData.chatType) { result in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    switch result {
                    case .success(_):
                        os_log("Updated group (%@) data", log: logger, type: .default, chatData.chatID as CVarArg)
                        let event = UpdatedGroupInfoEvent(name: name, description: description, chatID: chatData.chatID)
                        eventPublisher.publish(event: event)
                        self.routeBack()
                    case .failure(let failure):
                        _ = errorHandler.handleError(failure)
                        os_log("Failed to update group (%@) data", log: logger, type: .default, chatData.chatID as CVarArg)
                        print(failure)
                    }
                }
            }
        }
    }
    
    func updateGroupPhoto(_ image: UIImage) {
        uploadFile(image) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                os_log("Upload group (%@) photo to file storage", log: logger, type: .default, chatData.chatID as CVarArg)
                worker.updateGroupPhoto(chatData.chatID, data.fileId, chatData.chatType) { result in
                    switch result {
                    case .success(_):
                        os_log("Upload group (%@) photo", log: self.logger, type: .default, self.chatData.chatID as CVarArg)
                        let event = UpdatedGroupPhotoEvent(photo: image, photoURL: data.fileURL, chatID: self.chatData.chatID )
                        self.eventPublisher.publish(event: event)
                    case .failure(let failure):
                        _ = self.errorHandler.handleError(failure)
                        os_log("Failed to upload group (%@) photo", log: self.logger, type: .fault, self.chatData.chatID as CVarArg)
                        print(failure)
                    }
                }
            case .failure(let failure):
                _ = self.errorHandler.handleError(failure)
                os_log("Failed to upload group (%@) photo to file storage", log: logger, type: .fault, chatData.chatID as CVarArg)
                print(failure)
            }
        }
    }
    
    private func uploadFile(_ image: UIImage, completion: @escaping (Result<SuccessModels.UploadResponse, any Error>) -> Void) {
        os_log("Started saving image in profile setting screen", log: logger, type: .default)
        guard let data = image.jpegData(compressionQuality: 0.0) else {
            return
        }
        let fileName = "\(UUID().uuidString).jpeg"
        worker.uploadFile(data, fileName, "image/jpeg") { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let fileMetaData):
                ImageCacheManager.shared.saveImage(image, for: fileMetaData.fileURL as NSURL)
                completion(.success(fileMetaData))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func routeBack() {
        onRouteBack?()
    }
}
