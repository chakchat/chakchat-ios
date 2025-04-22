//
//  OnlineVisibilityScreenInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 31.01.2025.
//

import Foundation
import OSLog

// MARK: - OnlineVisibilityScreenInteractor
final class OnlineVisibilityScreenInteractor: OnlineVisibilityScreenBusinessLogic {

    // MARK: - Properties
    private let presenter: OnlineVisibilityScreenPresentationLogic
    private let worker: OnlineVisibilityScreenWorkerLogic
    private let eventManager: EventPublisherProtocol
    private let onlineRestrictionSnap: OnlineVisibilityStatus
    private let logger: OSLog
    
    var onRouteToConfidentialityScreen: (() -> Void)?
    var onRouteToAddUsersScreen: (() -> Void)?
    var selectedUsers: [ProfileSettingsModels.ProfileUserData] = []
    
    // MARK: - Initialization
    init(presenter: OnlineVisibilityScreenPresentationLogic, 
         worker: OnlineVisibilityScreenWorkerLogic,
         eventManager: EventPublisherProtocol,
         onlineRestrictionSnap: OnlineVisibilityStatus,
         logger: OSLog
    ) {
        self.presenter = presenter
        self.worker = worker
        self.eventManager = eventManager
        self.onlineRestrictionSnap = onlineRestrictionSnap
        self.logger = logger
    }
    
    // MARK: - Public Methods
    func loadUserRestrictions() {
        os_log("Loaded user data in online visibility screen", log: logger, type: .default)
        showUserRestrictions(onlineRestrictionSnap)
    }
    
    func showUserRestrictions(_ onlineRestriction: OnlineVisibilityStatus) {
        os_log("passed online restriction to online visibility vc", log: logger, type: .default)
        presenter.showUserRestrictions(onlineRestriction)
    }
    
    func saveNewRestrictions(_ onlineRestriction: OnlineVisibilityStatus) {
        os_log("Saved new online restriction", log: logger, type: .default)
        worker.saveNewRestrictions(onlineRestriction)
    }
    
    func backToConfidentialityScreen(_ onlineRestriction: String) {
        let newOnlineRestriction = OnlineVisibilityStatus(status: onlineRestriction)
        saveNewRestrictions(newOnlineRestriction)
        let updateOnlineRestrictionEvent = UpdateOnlineRestrictionEvent(newOnline: newOnlineRestriction.status)
        os_log("Event published in phone visibility screen", log: logger, type: .default)
        eventManager.publish(event: updateOnlineRestrictionEvent)
        os_log("Routed to confidentiality settings screen", log: logger, type: .default)
        onRouteToConfidentialityScreen?()
    }
    
    func showAddUsersScreen() {
        onRouteToAddUsersScreen?()
    }
}
