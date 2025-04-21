//
//  ReactionUpdate+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 20.04.2025.
//
//

import Foundation
import CoreData


extension ReactionUpdate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReactionUpdate> {
        return NSFetchRequest<ReactionUpdate>(entityName: "ReactionUpdate")
    }

    @NSManaged public var chatID: UUID?
    @NSManaged public var updateID: Int64
    @NSManaged public var type: String?
    @NSManaged public var senderID: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var reaction: String?
    @NSManaged public var messageID: Int64
    @NSManaged public var message: TextUpdate?
    @NSManaged public var fileMessage: FileUpdate?

}

extension ReactionUpdate : Identifiable {

}
