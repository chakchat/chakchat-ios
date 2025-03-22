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
    
    func saveNewRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData) {
        os_log("Saved new data in phone visibility screen", log: logger, type: .default)
        worker.saveNewRestrictions(userRestrictions)
    }
    
    // MARK: - Routing
    /// в будущем нужно будет не стринг передавать а целиком ConfidentialityDetails
    /// пока что стринг, потому что я сохраняю только статус кому открыта видимость номера телефона
    /// а UUID выбранных пользователей нет, потому что тот сервис я еще не трогал
    /// в dateOfBirth кладу значение из моего снапа, потому что оно не поменялось
    func backToConfidentialityScreen(_ userRestriction: String) {
        let newUserRestrictions = ConfidentialitySettingsModels.ConfidentialityUserData(
            phone: ConfidentialityDetails(openTo: userRestriction, specifiedUsers: nil),
            dateOfBirth: userRestrictionsSnap.dateOfBirth)
        worker.updateUserRestriction(newUserRestrictions) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                os_log("Saved user restrictions", log: logger, type: .default)
                self.saveNewRestrictions(data)
                let updateRestrictionsEvent = UpdateRestrictionsEvent(newPhone: data.phone,
                                                                      newDateOfBirth: data.dateOfBirth)
                eventManager.publish(event: updateRestrictionsEvent)
                onRouteToConfidentialityScreen?()
            case .failure(let failure):
                _ = self.errorHandler.handleError(failure)
                os_log("Failed to save restrictions", log: logger, type: .fault)
                print(failure)
                onRouteToConfidentialityScreen?()
            }
        }
    }
}
