//
//  CoreDataManager.swift
//  chakchat
//
//  Created by Кирилл Исаев on 28.02.2025.
//

import Foundation
import CoreData

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
    
    func createUpdate(_ updateData: UpdateData) {
        let context = CoreDataStack.shared.viewContext(for: Models.update.rawValue)
//        let updateEntity: Update
//        switch updateData.content {
//        case .textContent(let textContent):
//            let textUpdate = TextMessageUpdate(context: context)
//            textUpdate.text = textContent.text
//            if let replyToID = textContent.replyTo {
//                textUpdate.replyTo = fetchUpdate(by: replyToID)
//            }
//            updateEntity = textUpdate
//        case .fileContent(let fileContent):
//            let fileUpdate = FileMessageUpdate(context: context)
//            fileUpdate.fileID = fileContent.fileID
//            fileUpdate.fileName = fileContent.fileName
//            fileUpdate.fileSize = fileContent.fileSize
//            fileUpdate.fileURL = fileContent.fileURL.absoluteString
//            fileUpdate.mimeType = fileContent.mimeType
//            fileUpdate.fileCreatedAt = updateData.createdAt
//            
//            updateEntity = fileUpdate
//            
//        case .reactionContent(let reactionContent):
//            let reactionUpdate = ReactionUpdate(context: context)
//            reactionUpdate.reaction = reactionContent.reaction
//            reactionUpdate.message = fetchUpdate(by: reactionContent.messageID)
//            
//            updateEntity = reactionUpdate
//            
//        case .editedContent(let editedContent):
//            let editUpdate = TextMessageEditedUpdate(context: context)
//            editUpdate.newText = editedContent.newText
//            editUpdate.message = fetchUpdate(by: editedContent.messageID)
//            
//            updateEntity = editUpdate
//            
//        case .deletedContent(let deletedContent):
//            let deleteUpdate = DeletedUpdate(context: context)
//            deleteUpdate.mode = deletedContent.deletedMode.rawValue
//            deleteUpdate.deletedUpdate = fetchUpdate(by: deletedContent.deletedID)
//            
//            updateEntity = deleteUpdate
//        }
//        
//        updateEntity.chatID = updateData.chatID
//        updateEntity.senderID = updateData.senderID
//        updateEntity.createdAt = updateData.createdAt
//        updateEntity.updateID = updateData.updateID
//        updateEntity.type = updateData.type.rawValue
        
        CoreDataStack.shared.saveContext(for: Models.user.rawValue)
    }
    

}
