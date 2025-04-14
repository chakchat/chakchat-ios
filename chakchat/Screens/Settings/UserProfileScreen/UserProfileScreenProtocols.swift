//
//  UserProfileScreenProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 06.02.2025.
//

import UIKit

// MARK: - UserProfileScreen Protocols
protocol UserProfileScreenBusinessLogic {
    func backToSettingsMenu()
    func profileSettingsRoute()
    
    func loadUserData()
    func showUserData(_ userData: ProfileSettingsModels.ProfileUserData)
    func showNewUserData(_ userData: ProfileSettingsModels.ChangeableProfileUserData)
    func showNewPhoto(_ photo: URL?)
    
    func handleUserDataChangedEvent(_ event: UpdateProfileDataEvent)
    func handlePhotoChangedEvent(_ event: UpdatePhotoEvent)
    func signOut()
}

protocol UserProfileScreenPresentationLogic {
    func showUserData(_ userData: ProfileSettingsModels.ProfileUserData)
    func showNewUserData(_ userData: ProfileSettingsModels.ChangeableProfileUserData)
    func showNewPhoto(_ photo: URL?)
}

protocol UserProfileScreenWorkerLogic {
    func getUserData() -> ProfileSettingsModels.ProfileUserData
    func signOut(completion: @escaping (Result<Void, Error>) -> Void)
}
