//
//  Chat+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 10.04.2025.
//
//

import Foundation
import CoreData


extension Chat {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Chat> {
        return NSFetchRequest<Chat>(entityName: "Chat")
    }

    @NSManaged public var chatID: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var info: Data?
    @NSManaged public var members: [UUID]?
    @NSManaged public var type: String?

}

extension Chat : Identifiable {

}
