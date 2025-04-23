//
//  ChatsScreenInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 21.01.2025.
//

import UIKit
import OSLog
import Combine

// MARK: - ChatsScreenInteractor
final class ChatsScreenInteractor: ChatsScreenBusinessLogic {
        
    // MARK: - Properties
    private let presenter: ChatsScreenPresentationLogic
    private let worker: ChatsScreenWorkerLogic
    private let logger: OSLog
    private let errorHandler: ErrorHandlerLogic
    private let eventSubscriber: EventSubscriberProtocol
    private let keychainManager: KeychainManagerBusinessLogic
    
    private var cancellables = Set<AnyCancellable>()
    
    var onRouteToChat: ((ProfileSettingsModels.ProfileUserData, ChatsModels.GeneralChatModel.ChatData?) -> Void)?
    var onRouteToGroupChat: ((ChatsModels.GeneralChatModel.ChatData) -> Void)?
    var onRouteToSettings: (() -> Void)?
    var onRouteToNewMessage: (() -> Void)?
    
    // MARK: - Initialization
    init(presenter: ChatsScreenPresentationLogic, 
         worker: ChatsScreenWorkerLogic,
         logger: OSLog,
         errorHandler: ErrorHandlerLogic,
         eventSubscriber: EventSubscriberProtocol,
         keychainManager: KeychainManagerBusinessLogic
    ) {
        self.presenter = presenter
        self.worker = worker
        self.logger = logger
        self.errorHandler = errorHandler
        self.eventSubscriber = eventSubscriber
        self.keychainManager = keychainManager
        
        subscribeToEvents()
    }
    
    
    // MARK: - Public Methods
    func loadMeData() {
        os_log("Fetching for user data", log: logger, type: .default)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.worker.loadMeData() { result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(_):
                        os_log("Loaded user data", log: self.logger, type: .default)
                        break
                    case .failure(let failure):
                        _ = self.errorHandler.handleError(failure)
                        os_log("Failure in fetching user data:\n", log: self.logger, type: .fault)
                        print(failure)
                    }
                }
            }
        }
    }
    
    func loadMeRestrictions() {
        os_log("Fetching for user restrictions", log: logger, type: .default)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.worker.loadMeRestrictions { result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(_):
                        os_log("Loaded user restrictions", log: self.logger, type: .default)
                        break
                    case .failure(let failure):
                        _ = self.errorHandler.handleError(failure)
                        os_log("Failure in fetching user restrictions:\n", log: self.logger, type: .fault)
                        print(failure)
                    }
                }
            }
        }
    }
    
    func loadChats() {
        self.showDBChats()
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.worker.loadChats() { result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let data):
                        os_log("Loaded chats data", log: self.logger, type: .default)
                        self.showChats(data)
                        self.refreshChats(data)
                    case .failure(let failure):
                        self.showDBChats()
                        _ = self.errorHandler.handleError(failure)
                        os_log("Failure in fetching chats:\n", log: self.logger, type: .fault)
                        print(failure)
                    }
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
    
    private func subscribeToEvents() {
        eventSubscriber.subscribe(CreatedChatEvent.self) { [weak self] event in
            self?.handleCreatedChatEvent(event)
        }.store(in: &cancellables)
        eventSubscriber.subscribe(DeletedChatEvent.self) { [weak self] event in
            self?.handleDeletedChatEvent(event)
        }.store(in: &cancellables)
    }
    
    func handleCreatedChatEvent(_ event: CreatedChatEvent) {
        let newChat = ChatsModels.GeneralChatModel.ChatData(
            chatID: event.chatID,
            type: event.type,
            members: event.members,
            createdAt: event.createdAt,
            info: event.info,
            updatePreview: nil
        )
        DispatchQueue.main.async {
            self.addNewChat(newChat)
        }
    }
    
    func handleDeletedChatEvent(_ event: DeletedChatEvent) {
        let chatToDelete = event.chatID
        DispatchQueue.main.async {
            self.deleteChat(chatToDelete)
        }
    }
    
    func showChats(_ allChatsData: ChatsModels.GeneralChatModel.ChatsData) {
        presenter.showChats(allChatsData)
    }
    
    private func refreshChats(_ chats: ChatsModels.GeneralChatModel.ChatsData) {
        worker.refreshChats(chats)
    }
    
    func showDBChats() {
        let chats = worker.getDBChats()
        if let chats {
            let allChatsData = ChatsModels.GeneralChatModel.ChatsData(chats: chats)
            presenter.showChats(allChatsData)
        }
    }
    
    func addNewChat(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        presenter.addNewChat(chatData)
    }
    
    func deleteChat(_ chatID: UUID) {
        presenter.deleteChat(chatID)
    }
    
    func searchForExistingChat(_ userData: ProfileSettingsModels.ProfileUserData) {
        if let chatData = worker.searchForExistingChat(userData.id),
           let convertedChatData = mapFromCoreData(chatData) {
            onRouteToChat?(userData, convertedChatData)
        } else {
            onRouteToChat?(userData, nil)
        }
    }
    
    func getChatInfo(_ chat: ChatsModels.GeneralChatModel.ChatData, completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatInfo, any Error>) -> Void) {
        switch chat.type {
        case .personal, .secretPersonal:
            getUserDataByID(chat.members) { [weak self] result in
                guard self != nil else { return }
                switch result {
                case .success(let data):
                    let chatInfo = ChatsModels.GeneralChatModel.ChatInfo(chatName: data.name, chatPhotoURL: data.photo)
                    completion(.success(chatInfo))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        case .group, .secretGroup:
            if case .group(let groupInfo) = chat.info {
                let info = ChatsModels.GeneralChatModel.ChatInfo(chatName: groupInfo.name, chatPhotoURL: groupInfo.groupPhoto)
                completion(.success(info))
            }
            if case .secretGroup(let groupSecretInfo) = chat.info {
                let info = ChatsModels.GeneralChatModel.ChatInfo(chatName: groupSecretInfo.name, chatPhotoURL: groupSecretInfo.groupPhoto)
                completion(.success(info))
            }
        }
    }
    
    func getUserDataByID(_ users: [UUID], completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, Error>) -> Void) {
        worker.getUserDataByID(users) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func handleError(_ error: Error) {
        _ = errorHandler.handleError(error)
        os_log("Failed:\n", log: logger, type: .fault)
        print(error)
    }
    
    // MARK: - Routing
    func routeToSettingsScreen() {
        os_log("Routed to settings screen", log: logger, type: .default)
        onRouteToSettings?()
    }
    
    func routeToNewMessageScreen() {
        os_log("Routed to new message screen", log: logger, type: .default)
        onRouteToNewMessage?()
    }
    
    func routeToChat(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        switch chatData.type {
        case .personal, .secretPersonal:
            getUserDataByID(chatData.members) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let data):
                        self.onRouteToChat?(data, chatData)
                    case .failure(let failure):
                        _ = self.errorHandler.handleError(failure)
                        os_log("Failure in routing to chat:\n", log: self.logger, type: .fault)
                        print(failure)
                    }
                }
            }
        case .group, .secretGroup:
            self.onRouteToGroupChat?(chatData)
            break
        }
    }
    
    private func mapFromCoreData(_ chatCoreData: Chat) -> ChatsModels.GeneralChatModel.ChatData? {
        let decoder = JSONDecoder()
        guard let chatID = chatCoreData.chatID,
              let typeString = chatCoreData.type,
              let type = ChatType(rawValue: typeString),
              let members = chatCoreData.members,
              let createdAt = chatCoreData.createdAt,
              let infoData = chatCoreData.info,
              let info = (try? decoder.decode(ChatsModels.GeneralChatModel.Info.self, from: infoData))
        else { return nil }
        
        return ChatsModels.GeneralChatModel.ChatData(
            chatID: chatID,
            type: type,
            members: members,
            createdAt: createdAt,
            info: info,
            updatePreview: nil
        )
    }
}
