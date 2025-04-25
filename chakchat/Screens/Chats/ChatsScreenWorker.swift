//
//  ChatsScreenWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 21.01.2025.
//

import UIKit
import OSLog

// MARK: - ChatsScreenWorker
final class ChatsScreenWorker: ChatsScreenWorkerLogic {
    
    // MARK: - Properties
    private let keychainManager: KeychainManagerBusinessLogic
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let userService: UserServiceProtocol
    private let chatsService: ChatsServiceProtocol
    private let logger: OSLog
    
    // MARK: - Initialization
    init(keychainManager: KeychainManagerBusinessLogic,
         userDefaultsManager: UserDefaultsManagerProtocol,
         userService: UserServiceProtocol,
         chatsService: ChatsServiceProtocol,
         coreDataManager: CoreDataManagerProtocol,
         logger: OSLog
    ) {
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
        self.coreDataManager = coreDataManager
        self.userService = userService
        self.chatsService = chatsService
        self.logger = logger
    }
    
    func loadMeData(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        userService.sendGetMeRequest(accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.userDefaultsManager.saveUserData(response.data)
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func loadMeRestrictions(completion: @escaping (Result<Void, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        userService.sendGetRestrictionRequest(accessToken) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.userDefaultsManager.saveRestrictions(response.data)
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func loadChats(completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatsData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        chatsService.sendGetChatsRequest(accessToken) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.coreDataManager.createChats(response.data)
                    }
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    
    func fetchUsers(_ name: String?, _ username: String?, _ page: Int, _ limit: Int, completion: @escaping (Result<ProfileSettingsModels.Users, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        userService.sendGetUsersRequest(name, username, page, limit, accessToken) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.coreDataManager.createUsers(response.data)
                    }
                    completion(.success(response.data))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
    
    func getUserDataByID(_ users: [UUID], completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, any Error>) -> Void) {
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        let myID = getMyID()
        for user in users where user != myID {
            userService.sendGetUserRequest(user, accessToken) { [weak self] result in
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
    
    func getDBChats() -> [ChatsModels.GeneralChatModel.ChatData]? {
        let chats = coreDataManager.fetchChats()
        let mappedChats = mapFromCoreData(chats)
        return mappedChats
    }
    
    func refreshChats(_ chats: ChatsModels.GeneralChatModel.ChatsData) {
        DispatchQueue.main.async {
            self.coreDataManager.refreshChats(chats)
        }
    }
    
    func createChat(_ event: WSChatCreatedEvent) {
        let chatData = ChatsModels.GeneralChatModel.ChatData(
            chatID: event.chatCreatedData.chat.chatID,
            type: event.chatCreatedData.chat.type,
            members: event.chatCreatedData.chat.members,
            createdAt: event.chatCreatedData.chat.createdAt,
            info: event.chatCreatedData.chat.info,
            updatePreview: nil
        )
        coreDataManager.createChat(chatData)
    }
    
    func deleteChat(_ event: WSChatDeletedEvent) {
        coreDataManager.deleteChat(event.chatDeletedData.chatID)
    }
    
    func blockChat(_ event: WSChatBlockedEvent) {
        if let chat = coreDataManager.fetchChatByID(event.chatBlockedData.chatID) {
            if let mappedChat = mapFromCoreData([chat]) {
                if case .personal(var pi) = mappedChat[0].info {
                    pi.blockedBy?.append(event.chatBlockedData.senderID)
                    let newChatData = ChatsModels.GeneralChatModel.ChatData(
                        chatID: mappedChat[0].chatID,
                        type: mappedChat[0].type,
                        members: mappedChat[0].members,
                        createdAt: mappedChat[0].createdAt,
                        info: .personal(ChatsModels.GeneralChatModel.PersonalInfo(blockedBy: pi.blockedBy)),
                        updatePreview: nil
                    )
                    coreDataManager.updateChat(newChatData)
                }
            }
        }
    }
    
    func unblockChat(_ event: WSChatUnblockedEvent) {
        if let chat = coreDataManager.fetchChatByID(event.chatUnblockedData.chatID) {
            if let mappedChat = mapFromCoreData([chat]) {
                if case .personal(var pi) = mappedChat[0].info {
                    pi.blockedBy?.removeAll(where: {$0 == event.chatUnblockedData.senderID})
                    let newChatData = ChatsModels.GeneralChatModel.ChatData(
                        chatID: mappedChat[0].chatID,
                        type: mappedChat[0].type,
                        members: mappedChat[0].members,
                        createdAt: mappedChat[0].createdAt,
                        info: .personal(ChatsModels.GeneralChatModel.PersonalInfo(blockedBy: pi.blockedBy)),
                        updatePreview: nil
                    )
                    coreDataManager.updateChat(newChatData)
                }
            }
        }
    }
    
    func setExpiration(_ event: WSChatExpirationSetEvent) {
        if let chat = coreDataManager.fetchChatByID(event.chatExpirationSetData.chatID) {
            if let mappedChat = mapFromCoreData([chat]) {
                if case .secretPersonal(var spi) = mappedChat[0].info {
                    spi.expiration = event.chatExpirationSetData.expiration
                    let newChatData = ChatsModels.GeneralChatModel.ChatData(
                        chatID: event.chatExpirationSetData.chatID,
                        type: mappedChat[0].type,
                        members: mappedChat[0].members,
                        createdAt: mappedChat[0].createdAt,
                        info: .secretPersonal(ChatsModels.GeneralChatModel.SecretPersonalInfo(expiration: spi.expiration)),
                        updatePreview: nil
                    )
                    coreDataManager.updateChat(newChatData)
                }
                if case .secretGroup(var sgi) = mappedChat[0].info {
                    sgi.expiration = event.chatExpirationSetData.expiration
                    let newChatData = ChatsModels.GeneralChatModel.ChatData(
                        chatID: event.chatExpirationSetData.chatID,
                        type: mappedChat[0].type,
                        members: mappedChat[0].members,
                        createdAt: mappedChat[0].createdAt,
                        info: .secretGroup(
                            ChatsModels.GeneralChatModel.SecretGroupInfo(
                                sgi.admin,
                                sgi.name,
                                sgi.description,
                                sgi.groupPhoto,
                                sgi.expiration
                            )
                        ),
                        updatePreview: nil
                    )
                    coreDataManager.updateChat(newChatData)
                }
            }
        }
    }
    
    func changeGroupInfo(_ event: WSGroupInfoUpdatedEvent) {
        if let chat = coreDataManager.fetchChatByID(event.groupInfoUpdatedData.chatID) {
            if let mappedChat = mapFromCoreData([chat])?.first {
                if case .group(let gi) = mappedChat.info {
                    let newChatData = ChatsModels.GeneralChatModel.ChatData(
                        chatID: event.groupInfoUpdatedData.chatID,
                        type: mappedChat.type,
                        members: mappedChat.members,
                        createdAt: mappedChat.createdAt,
                        info: .group(
                            ChatsModels.GeneralChatModel.GroupInfo(
                                gi.admin,
                                event.groupInfoUpdatedData.name,
                                event.groupInfoUpdatedData.description,
                                event.groupInfoUpdatedData.groupPhoto
                            )
                        ),
                        updatePreview: nil
                    )
                    coreDataManager.updateChat(newChatData)
                }
                if case .secretGroup(let sgi) = mappedChat.info {
                    let newChatData = ChatsModels.GeneralChatModel.ChatData(
                        chatID: event.groupInfoUpdatedData.chatID,
                        type: mappedChat.type,
                        members: mappedChat.members,
                        createdAt: mappedChat.createdAt,
                        info: .secretGroup(
                            ChatsModels.GeneralChatModel.SecretGroupInfo(
                                sgi.admin,
                                event.groupInfoUpdatedData.name,
                                event.groupInfoUpdatedData.description,
                                event.groupInfoUpdatedData.groupPhoto,
                                sgi.expiration
                            )
                        ),
                        updatePreview: nil
                    )
                    coreDataManager.updateChat(newChatData)
                }
            }
        }
    }
    
    func addMember(_ event: WSGroupMembersAddedEvent) {
        if let chat = coreDataManager.fetchChatByID(event.groupMembersAddedData.chatID) {
            if var mappedChat = mapFromCoreData([chat])?.first {
                event.groupMembersAddedData.members.forEach { member in
                    mappedChat.members.append(member)
                }
                let newChatData = ChatsModels.GeneralChatModel.ChatData(
                    chatID: event.groupMembersAddedData.chatID,
                    type: mappedChat.type,
                    members: mappedChat.members,
                    createdAt: mappedChat.createdAt,
                    info: mappedChat.info,
                    updatePreview: nil
                )
                coreDataManager.updateChat(newChatData)
            }
        }
    }
    
    func removeMember(_ event: WSGroupMembersRemovedEvent) {
        if let chat = coreDataManager.fetchChatByID(event.groupMembersRemovedData.chatID) {
            if var mappedChat = mapFromCoreData([chat])?.first {
                let set = Set(event.groupMembersRemovedData.members)
                mappedChat.members = mappedChat.members.filter{!set.contains($0)}
                let newChatData = ChatsModels.GeneralChatModel.ChatData(
                    chatID: event.groupMembersRemovedData.chatID,
                    type: mappedChat.type,
                    members: mappedChat.members,
                    createdAt: mappedChat.createdAt,
                    info: mappedChat.info,
                    updatePreview: nil
                )
                coreDataManager.updateChat(newChatData)
            }
        }
    }
    
    func deleteDBchats() {
        DispatchQueue.main.async {
            self.coreDataManager.deleteAllChats()
        }
    }
    
    func getMyID() -> UUID {
        let myID = userDefaultsManager.loadID()
        return myID
    }
    
    func searchForExistingChat(_ memberID: UUID) -> Chat? {
        let myID = getMyID()
        let chat = coreDataManager.fetchChatByMembers(myID, memberID, ChatType.personal)
        return chat != nil ? chat : nil
    }
    
    private func mapFromCoreData(_ chats: [Chat]) -> [ChatsModels.GeneralChatModel.ChatData]? {
        var mappedChats: [ChatsModels.GeneralChatModel.ChatData] = []
        for chatCoreData in chats {
            let decoder = JSONDecoder()
            guard let chatID = chatCoreData.chatID,
                  let typeString = chatCoreData.type,
                  let type = ChatType(rawValue: typeString),
                  let members = chatCoreData.members,
                  let createdAt = chatCoreData.createdAt,
                  let infoData = chatCoreData.info,
                  let info = (try? decoder.decode(ChatsModels.GeneralChatModel.Info.self, from: infoData))
            else { return nil }
            
            let mappedChat = ChatsModels.GeneralChatModel.ChatData(
                chatID: chatID,
                type: type,
                members: members,
                createdAt: createdAt,
                info: info,
                updatePreview: nil
            )
            mappedChats.append(mappedChat)
        }
        return mappedChats
    }
}
