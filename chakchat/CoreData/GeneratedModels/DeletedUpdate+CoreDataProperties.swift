//
//  DeletedUpdate+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 05.04.2025.
//
//

import Foundation
import CoreData


extension DeletedUpdate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeletedUpdate> {
        return NSFetchRequest<DeletedUpdate>(entityName: "DeletedUpdate")
    }

    @NSManaged public var mode: String?
    @NSManaged public var deletedUpdate: Update?
    @NSManaged public var parentUpdate: Update?

}
