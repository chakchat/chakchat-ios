//
//  DeleteUpdate+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 20.04.2025.
//
//

import Foundation
import CoreData


extension DeleteUpdate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeleteUpdate> {
        return NSFetchRequest<DeleteUpdate>(entityName: "DeleteUpdate")
    }

    @NSManaged public var chatID: UUID?
    @NSManaged public var updateID: Int64
    @NSManaged public var type: String?
    @NSManaged public var senderID: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var deletedID: Int64
    @NSManaged public var deletedMode: String?

}

extension DeleteUpdate : Identifiable {

}
