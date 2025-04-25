//
//  CoreDataManager.swift
//  chakchat
//
//  Created by Кирилл Исаев on 28.02.2025.
//

import Foundation
import CoreData
import OSLog

// MARK: - CoreDataManager
final class CoreDataManager: CoreDataManagerProtocol {
 
    enum Models: String {
        case chat = "ChatsModel"
        case user = "UserModel"
        case update = "UpdateModel"
    }
    
    // MARK: Chats CRUD
    
    func createChat(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        let encoder = JSONEncoder()
        let context = CoreDataStack.shared.viewContext(for: Models.chat.rawValue)
        let chat = Chat(context: context)
        chat.chatID = chatData.chatID
        chat.type = chatData.type.rawValue
        chat.members = chatData.members
        chat.createdAt = chatData.createdAt
        chat.info = (try? encoder.encode(chatData.info)) ?? Data()
        CoreDataStack.shared.saveContext(for: Models.chat.rawValue)
    }
    
    func createChats(_ chatsData: ChatsModels.GeneralChatModel.ChatsData) {
        for chat in chatsData.chats {
            createChat(chat)
        }
        CoreDataStack.shared.saveContext(for: Models.chat.rawValue)
    }
    
    func fetchChatByID(_ chatID: UUID) -> Chat? {
        let context = CoreDataStack.shared.viewContext(for: Models.chat.rawValue)
        let request: NSFetchRequest<Chat> = Chat.fetchRequest()
        request.predicate = NSPredicate(format: "chatID == %@", chatID as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    func fetchUserByID(_ userID: UUID) -> User? {
        let context = CoreDataStack.shared.viewContext(for: Models.user.rawValue)
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userID as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    func fetchChats() -> [Chat] {
        let context = CoreDataStack.shared.viewContext(for: Models.chat.rawValue)
        let request: NSFetchRequest<Chat> = Chat.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            debugPrint("FetchChats failed(or empty)")
            return []
        }
    }
    
    func fetchChatByMembers(_ myID: UUID, _ memberID: UUID, _ type: ChatType) -> Chat? {
        let context = CoreDataStack.shared.viewContext(for: Models.chat.rawValue)
        let fetchRequest: NSFetchRequest<Chat> = Chat.fetchRequest()
        let predicate = NSPredicate(format: "type == %@", type.rawValue)
        fetchRequest.predicate = predicate
        do {
            let chats = try context.fetch(fetchRequest)
            for chat in chats {
                if let members = chat.members {
                    if members.contains(myID) && members.contains(memberID) {
                        return chat
                    }
                }
            }
        } catch {
            print("Failed to fetch chat by members: \(error.localizedDescription)")
        }
        return nil
    }

    func updateChat(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        let encoder = JSONEncoder()
        guard let chat = fetchChatByID(chatData.chatID) else {
            debugPrint("Chat not found in coredata")
            return
        }
        chat.members = chatData.members
        chat.createdAt = chatData.createdAt
        if case .personal(let info) = chatData.info {
            chat.info = (try? encoder.encode(info)) ?? Data()
        }
        if case .group(let info) = chatData.info {
            chat.info = (try? encoder.encode(info)) ?? Data()
        }
        if case .secretPersonal(let info) = chatData.info {
            chat.info = (try? encoder.encode(info)) ?? Data()
        }
        if case .secretGroup(let info) = chatData.info {
            chat.info = (try? encoder.encode(info)) ?? Data()
        }
        CoreDataStack.shared.saveContext(for: Models.chat.rawValue)
    }
    
    func deleteChat(_ chatID: UUID) {
        let context = CoreDataStack.shared.viewContext(for: Models.chat.rawValue)
        if let chat = fetchChatByID(chatID) {
            context.delete(chat)
        }
        CoreDataStack.shared.saveContext(for: Models.chat.rawValue)
    }
    
    func deleteAllChats() {
        let context = CoreDataStack.shared.viewContext(for: Models.chat.rawValue)
        let chats = fetchChats()
        for chat in chats {
            context.delete(chat)
        }
        CoreDataStack.shared.saveContext(for: Models.chat.rawValue)
    }
    
    
    func refreshChats(_ chatsData: ChatsModels.GeneralChatModel.ChatsData) {
        let context = CoreDataStack.shared.viewContext(for: Models.chat.rawValue)
        context.perform {
            self.deleteAllChats()
            self.createChats(chatsData)
        }
    }
    
    //MARK: Users CRUD
    
    func createUser(_ userData: ProfileSettingsModels.ProfileUserData) {
        let context = CoreDataStack.shared.viewContext(for: Models.user.rawValue)
        let user = User(context: context)
        user.id = userData.id
        user.name = userData.name
        user.username = userData.username
        user.phone = userData.phone
        user.photo = userData.photo
        user.dateOfBirth = userData.dateOfBirth
        user.createdAt = userData.createdAt
        CoreDataStack.shared.saveContext(for: Models.user.rawValue)
    }
    
    func createUsers(_ usersData: ProfileSettingsModels.Users) {
        for userData in usersData.users {
            createUser(userData)
        }
        CoreDataStack.shared.saveContext(for: Models.user.rawValue)
    }
    
    func fetchUsers() -> [User] {
        let context = CoreDataStack.shared.viewContext(for: Models.user.rawValue)
        let request: NSFetchRequest<User> = User.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            debugPrint("FetchUsers failed")
            return []
        }
    }
    
    func updateUser(_ newUserData: ProfileSettingsModels.ProfileUserData) {
        guard let user = fetchUserByID(newUserData.id) else { 
            debugPrint("User not found in coredata")
            return
        }
        user.name = newUserData.name
        user.username = newUserData.username
        user.phone = newUserData.phone
        if let photo = newUserData.photo { user.photo = photo }
        if let dateOfBirth = newUserData.dateOfBirth { user.dateOfBirth = dateOfBirth}
        user.createdAt = newUserData.createdAt
        CoreDataStack.shared.saveContext(for: Models.user.rawValue)
    }
    
    func deleteUser(_ user: User) {
        let context = CoreDataStack.shared.viewContext(for: Models.user.rawValue)
        context.delete(user)
        CoreDataStack.shared.saveContext(for: Models.user.rawValue)
    }
    
    func deleteAllUsers() {
        let context = CoreDataStack.shared.viewContext(for: Models.user.rawValue)
        let users = fetchUsers()
        for user in users {
            context.delete(user)
        }
        CoreDataStack.shared.saveContext(for: Models.user.rawValue)
    }
    
    // MARK: - Updates CRUD
    @discardableResult
    func createTextMessageUpdate(_ updateData: UpdateData) -> TextUpdate {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        let textMessageUpdate = TextUpdate(context: context)
        if case .textContent(let tc) = updateData.content {
            textMessageUpdate.chatID = updateData.chatID
            textMessageUpdate.updateID = updateData.updateID
            textMessageUpdate.type = updateData.type.rawValue
            textMessageUpdate.senderID = updateData.senderID
            textMessageUpdate.createdAt = updateData.createdAt
            textMessageUpdate.text = tc.text
            textMessageUpdate.replyTo = tc.replyTo ?? -1
            textMessageUpdate.forwarded = tc.forwarded ?? false
        }
        CoreDataStack.shared.saveContext(for: Models.update.rawValue)
        
        if case .textContent(let tc) = updateData.content, tc.edited != nil {
            textMessageUpdate.edited = createTextEditedUpdate(updateData)
            CoreDataStack.shared.saveContext(for: Models.update.rawValue)
        }
        
        if case .textContent(let tc) = updateData.content, tc.reactions != nil {
            if let reactions = tc.reactions {
                reactions.forEach { reaction in
                    textMessageUpdate.addToReactions(createReactionUpdateFromInfo(reaction))
                    CoreDataStack.shared.saveContext(for: Models.update.rawValue)
                }
            }
        }
        return textMessageUpdate
    }
    
    @discardableResult
    func createTextEditedUpdate(_ updateData: UpdateData) -> EditUpdate? {
        if case .textContent(let tc) = updateData.content {
            if tc.edited == nil {
                return nil
            }
        }
        
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        let textEditedUpdate = EditUpdate(context: context)
        textEditedUpdate.chatID = updateData.chatID
        textEditedUpdate.updateID = updateData.updateID
        textEditedUpdate.type = updateData.type.rawValue
        textEditedUpdate.senderID = updateData.senderID
        textEditedUpdate.createdAt = updateData.createdAt
        if case .editedContent(let ec) = updateData.content {
            textEditedUpdate.newText = ec.newText
            textEditedUpdate.messageID = ec.messageID
            textEditedUpdate.originalMessage = fetchTextMessageUpdate(ec.messageID)
        }
        if case .textContent(let tc) = updateData.content {
            guard let edited = tc.edited else { return nil }
            textEditedUpdate.newText = edited.content.newText
            textEditedUpdate.messageID = edited.content.messageID
            textEditedUpdate.originalMessage = fetchTextMessageUpdate(edited.content.messageID)
        }
        CoreDataStack.shared.saveContext(for: Models.update.rawValue)
        return textEditedUpdate
    }
    
    @discardableResult
    func createFileMessageUpdate(_ updateData: UpdateData) -> FileUpdate {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        
        if let existingUpdate = fetchFileMessageUpdate(updateData.updateID) {
            print("⚠️ FileUpdate с updateID \(updateData.updateID) уже существует!")
            return existingUpdate
        }
        
        let fileMessageUpdate = FileUpdate(context: context)
        fileMessageUpdate.chatID = updateData.chatID
        fileMessageUpdate.senderID = updateData.senderID
        fileMessageUpdate.updateID = updateData.updateID
        fileMessageUpdate.type = updateData.type.rawValue
        fileMessageUpdate.createdAt = updateData.createdAt
        if case .fileContent(let fc) = updateData.content {
            fileMessageUpdate.fileName = fc.file.fileName
            fileMessageUpdate.fileSize = Double(fc.file.fileSize)
            fileMessageUpdate.mimeType = fc.file.mimeType
            fileMessageUpdate.fileID = fc.file.fileID
            fileMessageUpdate.fileURL = fc.file.fileURL
            fileMessageUpdate.fileCreatedAt = fc.file.createdAt
            fileMessageUpdate.replyTo = fc.replyTo ?? -1
            fileMessageUpdate.forwarded = fc.forwarded ?? false
        }
        CoreDataStack.shared.saveContext(for: Models.update.rawValue)
        
        if case .fileContent(let fc) = updateData.content, fc.reactions != nil {
            if let reactions = fc.reactions {
                reactions.forEach { reaction in
                    fileMessageUpdate.addToReactions(createReactionUpdateFromInfo(reaction))
                    CoreDataStack.shared.saveContext(for: Models.update.rawValue)
                }
            }
        }
        return fileMessageUpdate
    }
    
    @discardableResult
    func createReactionUpdate(_ updateData: UpdateData) -> ReactionUpdate {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        let reactionUpdate = ReactionUpdate(context: context)
        reactionUpdate.chatID = updateData.chatID
        reactionUpdate.updateID = updateData.updateID
        reactionUpdate.type = updateData.type.rawValue
        reactionUpdate.senderID = updateData.senderID
        reactionUpdate.createdAt = updateData.createdAt
        if case .reactionContent(let rc) = updateData.content {
            reactionUpdate.reaction = rc.reaction
            reactionUpdate.messageID = rc.messageID
            
            if let textUpdate = fetchTextMessageUpdate(rc.messageID) {
                reactionUpdate.message = textUpdate
                reactionUpdate.fileMessage = nil
            }
            if let fileUpdate = fetchFileMessageUpdate(rc.messageID) {
                reactionUpdate.fileMessage = fileUpdate
                reactionUpdate.message = nil
            }
        }

        CoreDataStack.shared.saveContext(for: Models.update.rawValue)
        return reactionUpdate
    }
    
    @discardableResult
    func createDeletedUpdate(_ updateData: UpdateData) -> DeleteUpdate {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        let deletedUpdate = DeleteUpdate(context: context)
        deletedUpdate.chatID = updateData.chatID
        deletedUpdate.updateID = updateData.updateID
        deletedUpdate.type = updateData.type.rawValue
        deletedUpdate.senderID = updateData.senderID
        deletedUpdate.createdAt = updateData.createdAt
        if case .deletedContent(let dc) = updateData.content {
            deletedUpdate.deletedID = dc.deletedID
            deletedUpdate.deletedMode = dc.deletedMode.rawValue
        }
        CoreDataStack.shared.saveContext(for: Models.update.rawValue)
        return deletedUpdate
    }
    
    func fetchTextMessageUpdate(_ updateID: Int64) -> TextUpdate? {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        let request: NSFetchRequest<TextUpdate> = TextUpdate.fetchRequest()
        let predicate = NSPredicate(format: "updateID == %lld", updateID)
        request.predicate = predicate
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    func fetchTextEditedUpdate(_ updateID: Int64) -> EditUpdate? {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        let request: NSFetchRequest<EditUpdate> = EditUpdate.fetchRequest()
        let predicate = NSPredicate(format: "updateID == %lld", updateID)
        request.predicate = predicate
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    func fetchFileMessageUpdate(_ updateID: Int64) -> FileUpdate? {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        let request: NSFetchRequest<FileUpdate> = FileUpdate.fetchRequest()
        let predicate = NSPredicate(format: "updateID == %lld", updateID)
        request.predicate = predicate
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    func fetchReactionUpdate(_ updateID: Int64) -> ReactionUpdate? {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        let request: NSFetchRequest<ReactionUpdate> = ReactionUpdate.fetchRequest()
        let predicate = NSPredicate(format: "updateID == %lld", updateID)
        request.predicate = predicate
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    func fetchDeletedUpdate(_ updateID: Int64) -> DeleteUpdate? {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        let request: NSFetchRequest<DeleteUpdate> = DeleteUpdate.fetchRequest()
        let predicate = NSPredicate(format: "updateID == %lld", updateID)
        request.predicate = predicate
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    func updateTextMessageUpdate(_ updateData: UpdateData) {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        if let textUpdate = fetchTextMessageUpdate(updateData.updateID) {
            if let existingEdit = textUpdate.edited {
                context.delete(existingEdit)
            }
            if case .textContent(let tc) = updateData.content {
                textUpdate.text = tc.text
                textUpdate.replyTo = tc.replyTo ?? -1
                textUpdate.edited = createTextEditedUpdate(updateData)
                if let reactions = tc.reactions {
                    if let textUpdateR = textUpdate.reactions {
                        textUpdate.removeFromReactions(textUpdateR)
                    }
                    reactions.forEach { reaction in
                        textUpdate.addToReactions(createReactionUpdateFromInfo(reaction))
                    }
                }
            }
        }
        CoreDataStack.shared.saveContext(for: Models.update.rawValue)
    }
    
    func updateFileMessageUpdate(_ updateData: UpdateData) {
        _ = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        if let fileUpdate = fetchFileMessageUpdate(updateData.updateID) {
            if case .fileContent(let fc) = updateData.content {
                if let reactions = fc.reactions {
                    if let fileUpdateR = fileUpdate.reactions {
                        fileUpdate.removeFromReactions(fileUpdateR)
                    }
                    reactions.forEach { reaction in
                        fileUpdate.addToReactions(createReactionUpdateFromInfo(reaction))
                    }
                }
            }
        }
        CoreDataStack.shared.saveContext(for: Models.update.rawValue)
    }
    
    func deleteTextMessageUpdate(_ updateID: Int64) {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        if let textUpdate = fetchTextMessageUpdate(updateID) {
            context.delete(textUpdate)
        }
        CoreDataStack.shared.saveContext(for: Models.update.rawValue)
    }
    
    func deleteFileMessageUpdate(_ updateID: Int64) {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        if let fileUpdate = fetchFileMessageUpdate(updateID) {
            context.delete(fileUpdate)
        }
        CoreDataStack.shared.saveContext(for: Models.update.rawValue)
    }
    
    func fetchAllUpdates(_ chatID: UUID) -> [NSManagedObject] {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        var allUpdates: [NSManagedObject] = []

        let entityTypes: [NSFetchRequest<NSFetchRequestResult>] = [
            TextUpdate.fetchRequest(),
            FileUpdate.fetchRequest(),
            ReactionUpdate.fetchRequest(),
        ]

        for request in entityTypes {
            request.predicate = NSPredicate(format: "chatID == %@", chatID as CVarArg)

            do {
                let results = try context.fetch(request)
                if let updates = results as? [NSManagedObject] {
                    allUpdates.append(contentsOf: updates)
                }
            } catch {
                print("Error fetching updates for \(request.entityName ?? "Unknown"): \(error)")
            }
        }
        return allUpdates
    }
    
    private func createReactionUpdateFromInfo(_ reactionInfo: ReactionInfo) -> ReactionUpdate {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        let reactionUpdate = ReactionUpdate(context: context)
        reactionUpdate.chatID = reactionInfo.chatID
        reactionUpdate.updateID = reactionInfo.updateID
        reactionUpdate.type = reactionInfo.type.rawValue
        reactionUpdate.senderID = reactionInfo.senderID
        reactionUpdate.createdAt = reactionInfo.createdAt
        reactionUpdate.reaction = reactionInfo.content.reaction
        reactionUpdate.messageID = reactionInfo.content.messageID
        
        if let textUpdate = fetchTextMessageUpdate(reactionInfo.content.messageID) {
            reactionUpdate.message = textUpdate
            reactionUpdate.fileMessage = nil
        }
        if let fileUpdate = fetchFileMessageUpdate(reactionInfo.content.messageID) {
            reactionUpdate.fileMessage = fileUpdate
            reactionUpdate.message = nil
        }

        CoreDataStack.shared.saveContext(for: Models.update.rawValue)
        return reactionUpdate
    }
    
    func getLastUpdateID(_ chatID: UUID) -> Int64? {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
        var maxUpdateID: Int64? = nil

        let entities: [NSFetchRequest<NSFetchRequestResult>] = [
            TextUpdate.fetchRequest(),
            FileUpdate.fetchRequest(),
            EditUpdate.fetchRequest(),
            ReactionUpdate.fetchRequest(),
            DeleteUpdate.fetchRequest()
        ]

        for request in entities {
            request.predicate = NSPredicate(format: "chatID == %@", chatID as CVarArg)
            request.fetchLimit = 1
            request.sortDescriptors = [NSSortDescriptor(key: "updateID", ascending: false)]

            do {
                if let result = try context.fetch(request).first as? NSManagedObject,
                   let updateID = result.value(forKey: "updateID") as? Int64 {
                    if let currentMax = maxUpdateID {
                        maxUpdateID = max(currentMax, updateID)
                    } else {
                        maxUpdateID = updateID
                    }
                }
            } catch {
                print("Error fetching from \(request.entityName ?? "Unknown"): \(error.localizedDescription)")
            }
        }
        return maxUpdateID
    }
}
