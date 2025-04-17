//
//  NotificationScreenAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 31.01.2025.
//

import Foundation
import UIKit

// MARK: - NotificationScreenAssembly
enum NotificationScreenAssembly {
    
    static func build(with context: MainAppContextProtocol) -> UIViewController {
        let presenter = NotificationScreenPresenter()
        let worker = NotificationScreenWorker(userDefaultsManager: context.userDefaultsManager)
        let userData = getNotififcationData(context.userDefaultsManager)
        let interactor = NotificationScreenInteractor(presenter: presenter, 
                                                      worker: worker,
                                                      eventManager: context.eventManager,
                                                      userData: userData,
                                                      logger: context.logger
        )
        interactor.onRouteToSettingsMenu = {
            AppCoordinator.shared.popScreen()
        }
        let view = NotificationScreenViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}

private func getNotififcationData(_ userDefaultsManager: UserDefaultsManagerProtocol) -> NotificationScreenModels.NotificationStatus {
    let generalStatus = userDefaultsManager.loadGeneralNotificationStatus()
    let audioStatus = userDefaultsManager.loadAudioNotificationStatus()
    let vibrationStatus = userDefaultsManager.loadVibrationNotificationStatus()
    let userData = NotificationScreenModels.NotificationStatus(
        generalNotification: generalStatus,
        audioNotification: audioStatus,
        vibrationNotification: vibrationStatus
    )
    return userData
}
