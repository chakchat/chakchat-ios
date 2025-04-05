//
//  ReactionUpdate+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 05.04.2025.
//
//

import Foundation
import CoreData


extension ReactionUpdate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReactionUpdate> {
        return NSFetchRequest<ReactionUpdate>(entityName: "ReactionUpdate")
    }

    @NSManaged public var reaction: String?
    @NSManaged public var message: Update?
    @NSManaged public var parentUpdate: Update?

}
