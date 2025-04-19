//
//  PhoneVisibilityScreenInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 30.01.2025.
//

import Foundation
import OSLog

// MARK: - PhoneVisibilityScreenInteractor
final class PhoneVisibilityScreenInteractor: PhoneVisibilityScreenBusinessLogic {
    
    // MARK: - Properties
    private let presenter: PhoneVisibilityScreenPresenter
    private let worker: PhoneVisibilityScreenWorker
    private let eventManager: EventPublisherProtocol
    private let errorHandler: ErrorHandlerLogic
    private let logger: OSLog
    private let userRestrictionsSnap: ConfidentialitySettingsModels.ConfidentialityUserData
    
    var onRouteToConfidentialityScreen: (() -> Void)?
    var onRouteToAddUsersScreen: (() -> Void)?
    var selectedUsers: [ProfileSettingsModels.ProfileUserData] = []
    
    // MARK: - Initialization
    init(presenter: PhoneVisibilityScreenPresenter, 
         worker: PhoneVisibilityScreenWorker,
         eventManager: EventPublisherProtocol,
         errorHandler: ErrorHandlerLogic,
         logger: OSLog,
         userRestrictionsSnap: ConfidentialitySettingsModels.ConfidentialityUserData
    ) {
        self.presenter = presenter
        self.worker = worker
        self.eventManager = eventManager
        self.errorHandler = errorHandler
        self.logger = logger
        self.userRestrictionsSnap = userRestrictionsSnap
    }
    
    // MARK: - Public Methods
    func loadUserRestrictions() {
        os_log("Loaded user data in phone visibility screen", log: logger, type: .default)
        showUserRestrictions(userRestrictionsSnap)
    }
    
    func showUserRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData) {
        os_log("Passed user data in phone visibility screen to presenter", log: logger, type: .default)
        presenter.showUserRestrictions(userRestrictions)
    }
    
    func saveNewRestrictions(_ restriction: String) {
        let newUserRestrictions = ConfidentialitySettingsModels.ConfidentialityUserData(
            phone: ConfidentialityDetails(openTo: restriction, specifiedUsers: selectedUsers.map { $0.id }),
            dateOfBirth: userRestrictionsSnap.dateOfBirth)
        worker.updateUserRestriction(newUserRestrictions) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    os_log("Saved user restrictions", log: self.logger, type: .default)
                    let updateRestrictionsEvent = UpdateRestrictionsEvent(newPhone: data.phone,
                                                                          newDateOfBirth: data.dateOfBirth)
                    self.eventManager.publish(event: updateRestrictionsEvent)
                case .failure(let failure):
                    _ = self.errorHandler.handleError(failure)
                    os_log("Failed to save restrictions", log: self.logger, type: .fault)
                    print(failure)
                }
            }
        }
    }
    
    // MARK: - Routing
    func backToConfidentialityScreen() {
        onRouteToConfidentialityScreen?()
    }
    
    func showAddUsersScreen() {
        onRouteToAddUsersScreen?()
    }
}
