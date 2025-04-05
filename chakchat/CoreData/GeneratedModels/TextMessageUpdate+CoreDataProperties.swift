//
//  TextMessageUpdate+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 05.04.2025.
//
//

import Foundation
import CoreData


extension TextMessageUpdate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TextMessageUpdate> {
        return NSFetchRequest<TextMessageUpdate>(entityName: "TextMessageUpdate")
    }

    @NSManaged public var text: String?
    @NSManaged public var replyTo: Update?
    @NSManaged public var parentUpdate: Update?

}
