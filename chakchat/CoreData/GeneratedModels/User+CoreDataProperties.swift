//
//  User+CoreDataProperties.swift
//  chakchat
//
//  Created by Кирилл Исаев on 02.03.2025.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var username: String?
    @NSManaged public var phone: String?
    @NSManaged public var photo: URL?
    @NSManaged public var dateOfBirth: String?
    @NSManaged public var createdAt: Date?

}

extension User : Identifiable {

}
