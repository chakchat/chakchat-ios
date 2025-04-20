//
//  TextUpdate+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 20.04.2025.
//
//

import Foundation
import CoreData


extension TextUpdate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TextUpdate> {
        return NSFetchRequest<TextUpdate>(entityName: "TextUpdate")
    }

    @NSManaged public var chatID: UUID?
    @NSManaged public var updateID: Int64
    @NSManaged public var type: String?
    @NSManaged public var senderID: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var text: String?
    @NSManaged public var replyTo: Int64
    @NSManaged public var forwarded: Bool
    @NSManaged public var edited: EditUpdate?
    @NSManaged public var reactions: NSSet?

}

// MARK: Generated accessors for reactions
extension TextUpdate {

    @objc(addReactionsObject:)
    @NSManaged public func addToReactions(_ value: ReactionUpdate)

    @objc(removeReactionsObject:)
    @NSManaged public func removeFromReactions(_ value: ReactionUpdate)

    @objc(addReactions:)
    @NSManaged public func addToReactions(_ values: NSSet)

    @objc(removeReactions:)
    @NSManaged public func removeFromReactions(_ values: NSSet)

}

extension TextUpdate : Identifiable {

}
