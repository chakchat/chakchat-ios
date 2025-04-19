//
//  BirthVisibilityScreenInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 30.01.2025.
//

import Foundation
import OSLog

// MARK: - BirthVisibilityScreenInteractor
final class BirthVisibilityScreenInteractor: BirthVisibilityScreenBusinessLogic {

    // MARK: - Properties
    private let presenter: BirthVisibilityScreenPresentationLogic
    private let worker: BirthVisibilityScreenWorkerLogic
    private let eventManager: EventPublisherProtocol
    private let errorHandler: ErrorHandlerLogic
    private let logger: OSLog
    private let userRestrictionsSnap: ConfidentialitySettingsModels.ConfidentialityUserData
    
    var onRouteToConfidentialityScreen: (() -> Void)?
    var onRouteToAddUsersScreen: (() -> Void)?
    var selectedUsers: [ProfileSettingsModels.ProfileUserData] = []
    
    // MARK: - Initialization
    init(presenter: BirthVisibilityScreenPresentationLogic, 
         worker: BirthVisibilityScreenWorkerLogic,
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
        os_log("Loaded user data in birth visibility screen", log: logger, type: .default)
        showUserRestrictions(userRestrictionsSnap)
    }
    
    func showUserRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData) {
        os_log("Passed user data in birth visibility screen to presenter", log: logger, type: .default)
        presenter.showUserRestrictions(userRestrictions)
    }
    
    func saveNewRestrictions(_ restriction: String) {
        let newUserRestrictions = ConfidentialitySettingsModels.ConfidentialityUserData(
            phone: userRestrictionsSnap.phone,
            dateOfBirth: ConfidentialityDetails(openTo: restriction, specifiedUsers: selectedUsers.map { $0.id }))
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
                    os_log("Failed to save user restrictions", log: self.logger, type: .fault)
                    print(failure)
                    
                }
            }
        }
    }
    
    // MARK: - Rounting
    func backToConfidentialityScreen() {
        onRouteToConfidentialityScreen?()
    }
    
    func showAddUsersScreen() {
        onRouteToAddUsersScreen?()
    }
}
