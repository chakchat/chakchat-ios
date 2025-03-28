//
//  ConfidentialityScreenPresenter.swift
//  chakchat
//
//  Created by Кирилл Исаев on 28.01.2025.
//

import Foundation

// MARK: - ConfidentialityScreenPresenter
final class ConfidentialityScreenPresenter: ConfidentialityScreenPresentationLogic {
    
    // MARK: - Properties
    weak var view: ConfidentialityScreenViewController?
    
    // MARK: - Public Methods
    func showUserData(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData) {
        view?.configureSections(userRestrictions)
    }
    
    func showOnlineRestriction(_ onlineRestriction: OnlineVisibilityStatus) {
        view?.configureOnlineStatus(onlineRestriction)
    }
    
    func showNewUserData(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData) {
        view?.updateVisibilityStatus(userRestrictions)
    }
    
    func showNewOnlineRestriction(_ onlineRestriction: OnlineVisibilityStatus) {
        view?.updateOnlineStatus(onlineRestriction)
    }
}
