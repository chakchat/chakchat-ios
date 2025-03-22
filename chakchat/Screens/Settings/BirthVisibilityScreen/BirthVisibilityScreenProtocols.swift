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
    func backToConfidentialityScreen(_ birthRestriction: String)
    
    func loadUserRestrictions()
    func showUserRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData)
    func saveNewRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData)
}

protocol BirthVisibilityScreenPresentationLogic {
    func showUserRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData)
}

protocol BirthVisibilityScreenWorkerLogic {
    func updateUserRestriction(_ request: ConfidentialitySettingsModels.ConfidentialityUserData,
                               completion: @escaping (Result<ConfidentialitySettingsModels.ConfidentialityUserData, Error>) -> Void)
    func saveNewRestrictions(_ newUserRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData)
}
