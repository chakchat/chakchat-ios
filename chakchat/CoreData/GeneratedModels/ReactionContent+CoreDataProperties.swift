//
//  ReactionContent+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 28.02.2025.
//
//

import Foundation
import CoreData


extension ReactionContent {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReactionContent> {
        return NSFetchRequest<ReactionContent>(entityName: "ReactionContent")
    }

    @NSManaged public var reaction_: String?
    @NSManaged public var messageID: UUID?
    @NSManaged public var content: Content?

}

extension ReactionContent : Identifiable {

}
