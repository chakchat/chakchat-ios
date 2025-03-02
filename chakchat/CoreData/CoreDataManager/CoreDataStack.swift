//
//  CoreDataStack.swift
//  chakchat
//
//  Created by Кирилл Исаев on 02.03.2025.
//

import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    
    private var persistentContainers: [String: NSPersistentContainer] = [:]
        
    private func getPersistentContainer(for modelName: String) -> NSPersistentContainer {
        if let container = persistentContainers[modelName] {
            return container
        } else {
            let container = NSPersistentContainer(name: modelName)
            container.loadPersistentStores { (_, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
            persistentContainers[modelName] = container
            return container
        }
    }
    
    func viewContext(for modelName: String) -> NSManagedObjectContext {
        return getPersistentContainer(for: modelName).viewContext
    }
    
    func backgroundContext(for modelName: String) -> NSManagedObjectContext {
        return getPersistentContainer(for: modelName).newBackgroundContext()
    }
    
    func saveContext(for modelName: String) {
        let context = getPersistentContainer(for: modelName).viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func saveBackgroundContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
