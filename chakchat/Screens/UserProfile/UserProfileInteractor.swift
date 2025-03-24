//
//  UserProfileInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import UIKit
import OSLog

// MARK: - UserProfileInteractor
final class UserProfileInteractor: UserProfileBusinessLogic {
    
    // MARK: - Properties
    private let presenter: UserProfilePresentationLogic
    private let worker: UserProfileWorkerLogic
    private let errorHandler: ErrorHandlerLogic
    private let eventPublisher: EventPublisherProtocol
    private let userData: ProfileSettingsModels.ProfileUserData
    private let chatData: ChatsModels.GeneralChatModel.ChatData?
    private let profileConfiguration: ProfileConfiguration
    private let logger: OSLog
    
    var onRouteToChat: ((ProfileSettingsModels.ProfileUserData, ChatsModels.GeneralChatModel.ChatData?) -> Void)?
    var onRouteBack: (() -> Void)?
    var onRouteToMain: (() -> Void)?
    
    // MARK: - Initialization
    init(
        presenter: UserProfilePresentationLogic,
        worker: UserProfileWorkerLogic,
        errorHandler: ErrorHandlerLogic,
        eventPublisher: EventPublisherProtocol,
        userData: ProfileSettingsModels.ProfileUserData,
        chatData: ChatsModels.GeneralChatModel.ChatData?,
        profileConfiguration: ProfileConfiguration,
        logger: OSLog
    ) {
        self.presenter = presenter
        self.worker = worker
        self.errorHandler = errorHandler
        self.eventPublisher = eventPublisher
        self.userData = userData
        self.chatData = chatData
        self.profileConfiguration = profileConfiguration
        self.logger = logger
    }
    
    // MARK: - Public Methods
    func passUserData() {
        let isBlocked = checkIsBlocked(chatData)
        presenter.passUserData(isBlocked, userData, profileConfiguration)
    }
    
    func createSecretChat() {
        worker.createSecretChat(userData.id) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                os_log("Secret chat with id: %@ created", log: logger, type: .default, data.chatID as CVarArg)
                let event = CreatedChatEvent(
                    chatID: data.chatID,
                    type: data.type,
                    members: data.members,
                    createdAt: data.createdAt,
                    info: data.info
                )
                eventPublisher.publish(event: event)
            case .failure(let failure):
                _ = errorHandler.handleError(failure)
                os_log("Failed to cread secret chat with %@", log: logger, type: .fault, userData.id as CVarArg)
                print(failure)
            }
        }
    }
    
    func blockChat() {
        guard let chatID = chatData?.chatID else { return }
        worker.blockChat(chatID) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(_):
                    os_log("Chat with id:%@ is blocked", log: self.logger, type: .default, chatID as CVarArg)
                    let event = BlockedChatEvent(blocked: true)
                    self.eventPublisher.publish(event: event)
                    self.presenter.passBlocked()
                case .failure(let failure):
                    _ = self.errorHandler.handleError(failure)
                    os_log("Failed to block chat with %@", log: self.logger, type: .fault, chatID as CVarArg)
                    print(failure)
                }
            }
        }
    }
    
    func unblockChat() {
        guard let chatID = chatData?.chatID else { return }
        worker.unblockChat(chatID) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(_):
                    os_log("Chat with id:%@ is unblocked", log: self.logger, type: .default, chatID as CVarArg)
                    let event = BlockedChatEvent(blocked: false)
                    self.eventPublisher.publish(event: event)
                    self.presenter.passUnblocked()
                case .failure(let failure):
                    _ = self.errorHandler.handleError(failure)
                    os_log("Failed to unblock chat with %@", log: self.logger, type: .fault, chatID as CVarArg)
                    print(failure)
                }
            }
        }
    }
    
    func deleteChat(_ deleteMode: DeleteMode) {
        guard let chatID = chatData?.chatID else { return }
        worker.deleteChat(chatID, deleteMode) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(_):
                    os_log("Chat with id:%@ is deleted", log: self.logger, type: .default, self.userData.id as CVarArg)
                    let event = DeletedChatEvent(chatID: chatID)
                    self.eventPublisher.publish(event: event)
                    self.routeToChatsScreen()
                case .failure(let failure):
                    _ = self.errorHandler.handleError(failure)
                    os_log("Failed to delete chat with %@", log: self.logger, type: .fault, self.userData.id as CVarArg)
                    print(failure)
                }
            }

        }
    }
    
    func searchForExistingChat() {
        if let chatData = worker.searchForExistingChat(userData.id) {
            let convertedChatData = convertData(chatData)
            routeToChat(convertedChatData)
        } else {
            routeToChat(nil)
        }
    }
    
    func switchNotification() {
        /// сделать сохранение текущего состояния через userDefaultsManager, а может быть нужно как-то иначе сделать
        /// пока что реализация под вопросом
    }
    
    func searchMessages() {
        /// сделать через /{chatId}/update/message/search позже
    }
    
    // MARK: - Routing
    func routeToChat(_ isChatExisting: ChatsModels.GeneralChatModel.ChatData?) {
        onRouteToChat?(userData, isChatExisting)
    }
    
    func routeBack() {
        onRouteBack?()
    }
    
    func routeToChatsScreen() {
        onRouteToMain?()
    }
    
    private func convertData(_ chatCoreData: Chat) -> ChatsModels.GeneralChatModel.ChatData? {
        let decoder = JSONDecoder()
        let chatData = ChatsModels.GeneralChatModel.ChatData(
            chatID: chatCoreData.chatID,
            type: ChatType(rawValue: chatCoreData.type) ?? ChatType.personal,
            members: (try? decoder.decode([UUID].self, from: chatCoreData.members)) ?? [UUID()],
            createdAt: chatCoreData.createdAt,
            info: (try? decoder.decode(ChatsModels.GeneralChatModel.Info.self, from: chatCoreData.info))
            ?? ChatsModels.GeneralChatModel.Info.personal(ChatsModels.GeneralChatModel.PersonalInfo(blockedBy: [UUID()]))
        )
        return chatData
    }
    
    private func checkIsBlocked(_ chatData: ChatsModels.GeneralChatModel.ChatData?) -> Bool {
        let myID = worker.getMyID()
        if let chatData {
            if case .personal(let personalInfo) = chatData.info {
                let blockedBy = personalInfo.blockedBy
                    if blockedBy.contains(myID) {
                        return true
                    } else {
                        return false
                    }
            }
        }
        return false
    }
}
