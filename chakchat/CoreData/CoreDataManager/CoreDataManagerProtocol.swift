//
//  CoreDataManagerProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 28.02.2025.
//

import Foundation

protocol CoreDataManagerProtocol {
    func createUser(_ userData: ProfileSettingsModels.ProfileUserData)
    func fetchUsers() -> [User]
    func deleteUser(_ user: User)
    func deleteAllUsers()
}
