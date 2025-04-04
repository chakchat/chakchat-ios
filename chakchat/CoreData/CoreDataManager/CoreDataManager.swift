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
    
    func saveChats(_ chatsData: ChatsModels.GeneralChatModel.ChatsData) {
        let context = CoreDataStack.shared.viewContext(for: "ChatsModel")
        let encoder = JSONEncoder()
        for chat in chatsData.chats {
            let fetchRequest: NSFetchRequest<Chat> = Chat.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "chatID == %@", chat.chatID as CVarArg)
            if let existingChat = try? context.fetch(fetchRequest).first {
                existingChat.type = chat.type.rawValue
                existingChat.members = (try? encoder.encode(chat.members)) ?? Data()
                existingChat.createdAt = chat.createdAt
                existingChat.info = (try? encoder.encode(chat.info)) ?? Data()
            } else {
                let newChat = Chat(context: context)
                newChat.chatID = chat.chatID
                newChat.type = chat.type.rawValue
                newChat.members = (try? encoder.encode(chat.members)) ?? Data()
                newChat.createdAt = chat.createdAt
                newChat.info = (try? encoder.encode(chat.info)) ?? Data()
            }
        }
        CoreDataStack.shared.saveContext(for: "ChatsModel")
    }
    
    func fetchChats() -> [ChatsModels.GeneralChatModel.ChatData]? {
        let context = CoreDataStack.shared.viewContext(for: "ChatsModel")
        let fetchRequest: NSFetchRequest<Chat> = Chat.fetchRequest()
        do {
            let chats = try context.fetch(fetchRequest)
            var chatDataArray: [ChatsModels.GeneralChatModel.ChatData] = []
            for chat in chats {
                do {
                    let chatData = try chat.toChatData()
                    chatDataArray.append(chatData)
                } catch {
                    print("Failed to convert chat to ChatData: \(error)")
                    continue
                }
            }
            return chatDataArray
        } catch {
            print("Failed to fetch chats: \(error)")
            return nil
        }
    }
    
    func createChat(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        let encoder = JSONEncoder()
        let context = CoreDataStack.shared.viewContext(for: "ChatsModel")
        let chat = Chat(context: context)
        chat.chatID = chatData.chatID
        chat.type = chatData.type.rawValue
        chat.members = (try? encoder.encode(chatData.members)) ?? Data()
        chat.createdAt = chatData.createdAt
        chat.info = (try? encoder.encode(chatData.info)) ?? Data()
        CoreDataStack.shared.saveContext(for: "ChatsModel")
    }
    
    func fetchChatByMembers(_ myID: UUID, _ memberID: UUID, _ type: ChatType) -> Chat? {
        let context = CoreDataStack.shared.viewContext(for: "ChatsModel")
        let fetchRequest: NSFetchRequest<Chat> = Chat.fetchRequest()
        let predicate = NSPredicate(format: "type == %@", type.rawValue)
        fetchRequest.predicate = predicate
        do {
            let chats = try context.fetch(fetchRequest)
            for chat in chats {
                let members = chat.getMembers()
                if members.contains(myID) && members.contains(memberID) {
                    return chat
                }
            }
        } catch {
            print("Failed to fetch chat by members: \(error.localizedDescription)")
        }
        return nil
    }
    
    func updateChat(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        let context = CoreDataStack.shared.viewContext(for: "ChatsModel")
        let fetchRequest: NSFetchRequest<Chat> = Chat.fetchRequest()
        do {
            let chats = try context.fetch(fetchRequest)
            guard let chatToUpdate = chats.first else {
                print("No chat with id:\(chatData.chatID)")
                return
            }
            let newCreatedAt = chatData.createdAt
            chatToUpdate.createdAt = newCreatedAt
            let newInfo = (try? JSONEncoder().encode(chatData.info)) ?? Data()
            chatToUpdate.info = newInfo
            CoreDataStack.shared.saveContext(for: "ChatsModel")
            print("Chat with id:\(chatData.chatID) updated")
        } catch {
            print("Occurred error with chat(\(chatData.chatID)) update: \(error)")
        }
    }
    
    func deleteChat(_ chatID: UUID) {
        let context = CoreDataStack.shared.viewContext(for: "ChatsModel")
        let fetchRequest: NSFetchRequest<Chat> = Chat.fetchRequest()
        do {
            let chats = try context.fetch(fetchRequest)
            guard let chatToDelete = chats.first else {
                print("No chat with id:\(chatID)")
                return
            }
            context.delete(chatToDelete)
            CoreDataStack.shared.saveContext(for: "ChatsModel")
            print("Chat with id:\(chatID) deleted")
        } catch {
            print("Occurred error with chat(\(chatID)) update: \(error)")
        }
    }
    
    func deleteAllChats() {
        let context = CoreDataStack.shared.viewContext(for: "ChatsModel")
        let request: NSFetchRequest<NSFetchRequestResult> = Chat.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        do {
            try context.execute(deleteRequest)
            CoreDataStack.shared.saveContext(for: "ChatsModel")
        } catch {
            print("Delete error: \(error)")
        }
    }
    
    func refreshChats(_ chatsData: ChatsModels.GeneralChatModel.ChatsData) {
        let context = CoreDataStack.shared.viewContext(for: "ChatsModel")
        context.perform {
            self.deleteAllChats()
            self.saveChats(chatsData)
        }
    }
    
    func createUser(_ userData: ProfileSettingsModels.ProfileUserData) {
        let context = CoreDataStack.shared.viewContext(for: "UserModel")
        let user = User(context: context)
        user.id = userData.id
        user.name = userData.name
        user.username = userData.username
        user.phone = userData.phone
        user.photo = userData.photo
        user.dateOfBirth = userData.dateOfBirth
        user.createdAt = userData.createdAt
        CoreDataStack.shared.saveContext(for: "UserModel")
    }
    
    func createUsers(_ usersData: ProfileSettingsModels.Users) {
        for userData in usersData.users {
            createUser(userData)
        }
        CoreDataStack.shared.saveContext(for: "UserModel")
    }
    
    func fetchUsers() -> [UUID]? {
        let context = CoreDataStack.shared.viewContext(for: "ChatsModel")
        let fetchRequest: NSFetchRequest<Chat> = Chat.fetchRequest()
        var res: [UUID]? = []
        do {
            let chats = try context.fetch(fetchRequest)
            for chat in chats {
                let members = try JSONDecoder().decode([UUID].self, from: chat.members)
                for member in members {
                    res?.append(member)
                }
            }
            if let res {
                return Array(Set(res))
            }
            return nil
        } catch {
            print("Error in FetchUsers")
            return nil
        }
    }
    
    func deleteUser(_ user: User) {
        let context = CoreDataStack.shared.viewContext(for: "UserModel")
        context.delete(user)
        CoreDataStack.shared.saveContext(for: "UserModel")
    }
    
    func deleteAllUsers() {
        let context = CoreDataStack.shared.viewContext(for: "UserModel")
        let request: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        do {
            try context.execute(deleteRequest)
            CoreDataStack.shared.saveContext(for: "UserModel")
        } catch {
            print("Delete error: \(error)")
        }
    }
}
