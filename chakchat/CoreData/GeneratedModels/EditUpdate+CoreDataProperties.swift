//
//  EditUpdate+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 20.04.2025.
//
//

import Foundation
import CoreData


extension EditUpdate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EditUpdate> {
        return NSFetchRequest<EditUpdate>(entityName: "EditUpdate")
    }

    @NSManaged public var chatID: UUID?
    @NSManaged public var updateID: Int64
    @NSManaged public var type: String?
    @NSManaged public var senderID: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var newText: String?
    @NSManaged public var messageID: Int64
    @NSManaged public var originalMessage: TextUpdate?

}

extension EditUpdate : Identifiable {

}
