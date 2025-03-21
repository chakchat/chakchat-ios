//
//  UserProfileScreenPresenter.swift
//  chakchat
//
//  Created by Кирилл Исаев on 06.02.2025.
//

import Foundation

// MARK: - UserProfileScreenPresenter
final class UserProfileScreenPresenter: UserProfileScreenPresentationLogic {
        
    weak var view: UserProfileScreenViewController?
    
    // MARK: - Public Methods
    func showUserData(_ userData: ProfileSettingsModels.ProfileUserData) {
        view?.configureUserData(userData)
    }

    func showNewUserData(_ userData: ProfileSettingsModels.ChangeableProfileUserData) {
        view?.updateUserData(userData)
    }
    
    func showNewPhoto(_ photo: URL?) {
        view?.updatePhoto(photo)
    }
}
