//
//  UserProfilePresenter.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import UIKit

// MARK: - UserProfilePresenter
final class UserProfilePresenter: UserProfilePresentationLogic {
        
    weak var view: UserProfileViewController?

    func passUserData(
        _ isBlocked: Bool,
        _ userData: ProfileSettingsModels.ProfileUserData,
        _ profileConfiguration: ProfileConfiguration
    ) {
        view?.configureWithUserData(isBlocked, userData, profileConfiguration)
    }
    
    func passBlocked() {
        view?.passBlock()
    }
    
    func passUnblocked() {
        view?.passUnblock()
    }
    
    func showFailDisclaimer() {
        view?.showFailDisclaimer()
    }
}
