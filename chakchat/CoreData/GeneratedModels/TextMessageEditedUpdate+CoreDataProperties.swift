//
//  TextMessageEditedUpdate+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 05.04.2025.
//
//

import Foundation
import CoreData


extension TextMessageEditedUpdate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TextMessageEditedUpdate> {
        return NSFetchRequest<TextMessageEditedUpdate>(entityName: "TextMessageEditedUpdate")
    }

    @NSManaged public var newText: String?
    @NSManaged public var message: Update?
    @NSManaged public var parentUpdate: Update?

}
