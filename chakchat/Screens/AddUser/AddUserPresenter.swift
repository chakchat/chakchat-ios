//
//  AddUserPresenter.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.03.2025.
//

import UIKit

final class AddUserPresenter: AddUserPresentationLogic {
    
    weak var view: AddUserViewController?
    
    func loadData(_ users: [ProfileSettingsModels.ProfileUserData]) {
//        view?.configureWithCoreData(users)
    }
    
    func loadSpecifiedUsers(_ users: [UUID]?) {
//        guard let users else { return }
        
//        view?.configureWithSelectedUsers(users)
    }
}
