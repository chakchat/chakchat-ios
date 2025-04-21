//
//  FileUpdate+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 20.04.2025.
//
//

import Foundation
import CoreData


extension FileUpdate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FileUpdate> {
        return NSFetchRequest<FileUpdate>(entityName: "FileUpdate")
    }

    @NSManaged public var chatID: UUID?
    @NSManaged public var senderID: UUID?
    @NSManaged public var updateID: Int64
    @NSManaged public var type: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var fileName: String?
    @NSManaged public var fileSize: Double
    @NSManaged public var mimeType: String?
    @NSManaged public var fileID: UUID?
    @NSManaged public var fileURL: URL?
    @NSManaged public var fileCreatedAt: Date?
    @NSManaged public var replyTo: Int64
    @NSManaged public var forwarded: Bool
    @NSManaged public var reactions: NSSet?

}

// MARK: Generated accessors for reactions
extension FileUpdate {

    @objc(addReactionsObject:)
    @NSManaged public func addToReactions(_ value: ReactionUpdate)

    @objc(removeReactionsObject:)
    @NSManaged public func removeFromReactions(_ value: ReactionUpdate)

    @objc(addReactions:)
    @NSManaged public func addToReactions(_ values: NSSet)

    @objc(removeReactions:)
    @NSManaged public func removeFromReactions(_ values: NSSet)

}

extension FileUpdate : Identifiable {

}
