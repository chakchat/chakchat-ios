//
//  FileMessageUpdate+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 05.04.2025.
//
//

import Foundation
import CoreData


extension FileMessageUpdate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FileMessageUpdate> {
        return NSFetchRequest<FileMessageUpdate>(entityName: "FileMessageUpdate")
    }

    @NSManaged public var fileID: UUID?
    @NSManaged public var fileName: String?
    @NSManaged public var mimeType: String?
    @NSManaged public var fileSize: Int64
    @NSManaged public var fileURL: String?
    @NSManaged public var fileCreatedAt: Date?
    @NSManaged public var replyTo: Update?
    @NSManaged public var parentUpdate: Update?

}
