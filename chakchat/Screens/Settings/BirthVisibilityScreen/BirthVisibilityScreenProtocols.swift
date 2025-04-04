//
//  BirthVisibilityScreenProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 30.01.2025.
//

import Foundation

// MARK: - BirthVisibilityScreen Protocols
protocol BirthVisibilityScreenBusinessLogic {
    /// тут все аналогично экрану PhoneVisibility
    func backToConfidentialityScreen()
    
    func loadUserRestrictions()
    func showUserRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData)
    func saveNewRestrictions(_ restriction: String)
}

protocol BirthVisibilityScreenPresentationLogic {
    func showUserRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData)
}

protocol BirthVisibilityScreenWorkerLogic {
    func updateUserRestriction(_ request: ConfidentialitySettingsModels.ConfidentialityUserData,
                               completion: @escaping (Result<ConfidentialitySettingsModels.ConfidentialityUserData, Error>) -> Void)
}
