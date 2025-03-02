//
//  CoreDataManager.swift
//  chakchat
//
//  Created by Кирилл Исаев on 28.02.2025.
//

import Foundation
import CoreData

final class CoreDataManager: CoreDataManagerProtocol {
    
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
    
    func fetchUsers() -> [User] {
        let context = CoreDataStack.shared.viewContext(for: "UserModel")
        let request: NSFetchRequest<User> = User.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
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
