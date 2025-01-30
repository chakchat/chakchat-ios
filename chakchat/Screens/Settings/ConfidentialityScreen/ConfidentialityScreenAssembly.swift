//
//  ConfidentialityScreenAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 28.01.2025.
//

import Foundation
import UIKit
enum ConfidentialityScreenAssembly {
    static func build(with context: SignupContext, coordinator: AppCoordinator) -> UIViewController {
        let presenter = ConfidentialityScreenPresenter()
        let worker = ConfidentialityScreenWorker(userDefaultsManager: context.userDefaultManager)
        let userData = getUserConfData(context.userDefaultManager)
        let interactor = ConfidentialityScreenInteractor(presenter: presenter, worker: worker, eventPublisher: context.eventManager, userData: userData)
        
        interactor.onRouteToSettingsMenu = { [weak coordinator] in
            coordinator?.popScreen()
        }
        
        interactor.onRouteToPhoneVisibilityScreen = { [weak coordinator] in
            coordinator?.showPhoneVisibilityScreen()
        }
        
        interactor.onRouteToBirthVisibilityScreen = { [weak coordinator] in
            coordinator?.showBirthVisibilityScreen()
        }
        
        context.eventManager.register(eventType: UpdatePhoneStatusEvent.self, interactor.handlePhoneVisibilityChangeEvent)
        context.eventManager.register(eventType: UpdateBirthStatusEvent.self, interactor.handleBirthVisibilityChangeEvent)
        
        let view = ConfidentialityScreenViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}

func getUserConfData(_ userDefaultsManager: UserDefaultsManagerProtocol) -> ConfidentialitySettingsModels.ConfidentialityUserData {
    let phoneStatus = userDefaultsManager.loadConfidentialityPhoneStatus()
    let birthStatus = userDefaultsManager.loadConfidentialityDateOfBirthStatus()
    let onlineStatus = userDefaultsManager.loadConfidentialityOnlineStatus()
    
    guard let phoneStatus = ConfidentialityState(rawValue: phoneStatus),
          let birthStatus = ConfidentialityState(rawValue: birthStatus),
          let onlineStatus = ConfidentialityState(rawValue: onlineStatus) else {
        return ConfidentialitySettingsModels.ConfidentialityUserData(
            phoneNumberState: .all,
            dateOfBirthState: .all,
            onlineStatus: .all)
    }
    return ConfidentialitySettingsModels.ConfidentialityUserData(
        phoneNumberState: phoneStatus,
        dateOfBirthState: birthStatus,
        onlineStatus: onlineStatus)
}
