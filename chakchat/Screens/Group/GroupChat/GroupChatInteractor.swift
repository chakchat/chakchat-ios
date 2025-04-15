//
//  GroupChatInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import Foundation
import OSLog
import Combine
import MessageKit

final class GroupChatInteractor: GroupChatBusinessLogic {
    
    private let presenter: GroupChatPresentationLogic
    private let worker: GroupChatWorkerLogic
    private let eventSubscriber: EventSubscriberProtocol
    private let errorHandler: ErrorHandlerLogic
    private var chatData: ChatsModels.GeneralChatModel.ChatData
    private let logger: OSLog
    
    private var cancellables = Set<AnyCancellable>()
    
    var onRouteBack: (() -> Void)?
    var onRouteToGroupProfile: ((ChatsModels.GeneralChatModel.ChatData) -> Void)?
    
    init(
        presenter: GroupChatPresentationLogic,
        worker: GroupChatWorkerLogic,
        eventSubscriber: EventSubscriberProtocol,
        errorHandler: ErrorHandlerLogic,
        chatData: ChatsModels.GeneralChatModel.ChatData,
        logger: OSLog
    ) {
        self.presenter = presenter
        self.worker = worker
        self.eventSubscriber = eventSubscriber
        self.errorHandler = errorHandler
        self.chatData = chatData
        self.logger = logger
        
        subscribeToEvents()
    }
    
    func passChatData() {
        presenter.passChatData(chatData)
    }
       
    
    func loadFirstMessages(completion: @escaping (Result<[any MessageType], any Error>) -> Void) {
        worker.loadFirstMessages(chatData.chatID, 1, 200) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                let sortedUpdates = data.sorted { $0.updateID < $1.updateID }
                let mappedSortedUpdates = self.mapToMessageType(sortedUpdates)
                completion(.success(mappedSortedUpdates))
            case .failure(let failure):
                completion(.failure(failure))
                print(failure)
            }
        }
    }
    
    func sendTextMessage(_ message: String, _ replyTo: Int64?, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        worker.sendTextMessage(chatData.chatID, message, replyTo) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func deleteMessage(_ updateID: Int64, _ deleteMode: DeleteMode, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        worker.deleteMessage(chatData.chatID, updateID, deleteMode) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func editTextMessage(_ updateID: Int64, _ text: String, completion: @escaping (Result<UpdateData, any Error>) -> Void) {
        worker.editTextMessage(chatData.chatID, updateID, text) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    func sendFileMessage(_ fileID: UUID, _ replyTo: Int64?, completion: @escaping (Bool) -> Void) {
        worker.sendFileMessage(chatData.chatID, fileID, replyTo) { result in
            switch result {
            case .success(let data):
                completion(true)
            case .failure(let failure):
                completion(false)
                print(failure)
            }
        }
    }
    
    func sendReaction(_ reaction: String, _ messageID: Int64, completion: @escaping (Bool) -> Void) {
        worker.sendReaction(chatData.chatID, reaction, messageID) { result in
            switch result {
            case .success(let data):
                completion(true)
            case .failure(let failure):
                completion(false)
                print(failure)
            }
        }
    }
    
    func deleteReaction(_ updateID: Int64, completion: @escaping (Bool) -> Void) {
        worker.deleteReaction(chatData.chatID, updateID) { result in
            switch result {
            case .success(let data):
                completion(true)
            case .failure(let failure):
                completion(false)
                print(failure)
            }
        }
    }
    
    func handleAddedMemberEvent(_ event: AddedMemberEvent) {
        print("Handle new member")
    }
    
    func handleDeletedMemberEvent(_ event: DeletedMemberEvent) {
        if let i = chatData.members.firstIndex(of: event.memberID) {
            chatData.members.remove(at: i)
        }
    }
    
    func routeBack() {
        onRouteBack?()
    }
    
    func routeToChatProfile() {
        onRouteToGroupProfile?(chatData)
    }
    
    private func subscribeToEvents() {
        eventSubscriber.subscribe(AddedMemberEvent.self) { [weak self] event in
            self?.handleAddedMemberEvent(event)
        }.store(in: &cancellables)
        eventSubscriber.subscribe(DeletedMemberEvent.self) { [weak self] event in
            self?.handleDeletedMemberEvent(event)
        }.store(in: &cancellables)
    }
    
    func mapToTextMessage(_ update: UpdateData) -> GroupTextMessage {
        var mappedTextUpdate = GroupTextMessage()
        if case .textContent(let tc) = update.content {
            mappedTextUpdate.sender = GroupSender(senderId: update.senderID.uuidString, displayName: "", avatar: nil)
            mappedTextUpdate.messageId = String(update.updateID)
            mappedTextUpdate.sentDate = update.createdAt
            mappedTextUpdate.kind = .text(tc.text)
            mappedTextUpdate.text = tc.text
            mappedTextUpdate.replyTo = nil // на этапе ViewController'a
            mappedTextUpdate.replyToID = tc.replyTo
            mappedTextUpdate.isEdited = tc.edited != nil ? true : false
            if let edited = tc.edited {
                if case .editedContent(let ec) = edited.content {
                    mappedTextUpdate.editedMessage = ec.newText
                    mappedTextUpdate.text = ec.newText
                }
            }
            if let reactions = tc.reactions {
                var reactionsDict: [Int64: String] = [:]
                for reaction in reactions {
                    if case .reactionContent(let rc) = reaction.content {
                        reactionsDict.updateValue(rc.reaction, forKey: reaction.updateID)
                    }
                }
                mappedTextUpdate.reactions = reactionsDict
            }
        }
        return mappedTextUpdate
    }
    
    func mapToEditedMessage(_ update: UpdateData) -> GroupTextMessageEdited {
        var mappedTextEditedUpdate = GroupTextMessageEdited()
        if case .editedContent(let ec) = update.content {
            mappedTextEditedUpdate.sender = GroupSender(senderId: update.senderID.uuidString, displayName: "", avatar: nil)
            mappedTextEditedUpdate.messageId = String(update.updateID)
            mappedTextEditedUpdate.sentDate = update.createdAt
            mappedTextEditedUpdate.kind = .custom(Kind.GroupTextMessageEditedKind)
            mappedTextEditedUpdate.newText = ec.newText
            mappedTextEditedUpdate.oldTextUpdateID = ec.messageID
        }
        return mappedTextEditedUpdate
    }
    
    private func mapToMessageType(_ updates: [UpdateData]) -> [MessageType] {
        var mappedUpdates: [MessageType] = []
        for update in updates {
            switch update.type {
            case .textMessage:
                let mappedTextUpdate = mapToTextMessage(update)
                mappedUpdates.append(mappedTextUpdate)
            case .textEdited:
                let mappedEditedTextUpdate = mapToEditedMessage(update)
                mappedUpdates.append(mappedEditedTextUpdate)
            case .file:
                var mappedFileUpdate: GroupFileMessage!
                if case .fileContent(let fc) = update.content {
                    mappedFileUpdate.sender = GroupSender(senderId: update.senderID.uuidString, displayName: "", avatar: nil)
                    mappedFileUpdate.messageId = String(update.updateID)
                    mappedFileUpdate.sentDate = update.createdAt
                    mappedFileUpdate.kind = .custom(Kind.GroupFileMessageKind)
                    mappedFileUpdate.fileID = fc.fileID
                    mappedFileUpdate.fileName = fc.fileName
                    mappedFileUpdate.mimeType = fc.mimeType
                    mappedFileUpdate.fileSize = fc.fileSize
                    mappedFileUpdate.fileURL = fc.fileURL
                    if let reactions = fc.reactions {
                        var reactionsDict: [Int64: String] = [:]
                        for reaction in reactions {
                            if case .reactionContent(let rc) = reaction.content {
                                reactionsDict.updateValue(rc.reaction, forKey: reaction.updateID)
                            }
                        }
                        mappedFileUpdate.reactions = reactionsDict
                    }
                }
                mappedUpdates.append(mappedFileUpdate)
            case .reaction:
                var mappedReactionUpdate: GroupReaction!
                if case .reactionContent(let rc) = update.content {
                    mappedReactionUpdate.sender = GroupSender(senderId: update.senderID.uuidString, displayName: "", avatar: nil)
                    mappedReactionUpdate.messageId = String(update.updateID)
                    mappedReactionUpdate.sentDate = update.createdAt
                    mappedReactionUpdate.kind = .custom(Kind.GroupReactionKind)
                    mappedReactionUpdate.onMessageID = rc.messageID
                    mappedReactionUpdate.reaction = rc.reaction
                }
                mappedUpdates.append(mappedReactionUpdate)
            case .delete:
                var mappedDeleteUpdate: GroupMessageDelete!
                if case .deletedContent(let dc) = update.content {
                    mappedDeleteUpdate.sender = GroupSender(senderId: update.senderID.uuidString, displayName: "", avatar: nil)
                    mappedDeleteUpdate.messageId = String(update.updateID)
                    mappedDeleteUpdate.sentDate = update.createdAt
                    mappedDeleteUpdate.kind = .custom(Kind.GroupMessageDeleteKind)
                    mappedDeleteUpdate.deletedMessageID = dc.deletedID
                    mappedDeleteUpdate.deleteMode = dc.deletedMode
                }
                mappedUpdates.append(mappedDeleteUpdate)
            }
        }
        return mappedUpdates
    }
}
