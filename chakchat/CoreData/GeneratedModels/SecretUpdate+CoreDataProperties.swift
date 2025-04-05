//
//  SecretUpdate+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 05.04.2025.
//
//

import Foundation
import CoreData


extension SecretUpdate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SecretUpdate> {
        return NSFetchRequest<SecretUpdate>(entityName: "SecretUpdate")
    }

    @NSManaged public var payload: Data?
    @NSManaged public var keyHash: String?
    @NSManaged public var initializationVector: Data?
    @NSManaged public var parentUpdate: Update?

}
