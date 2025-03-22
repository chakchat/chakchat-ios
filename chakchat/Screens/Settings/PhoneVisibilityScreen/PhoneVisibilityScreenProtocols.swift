//
//  PhoneVisibilityScreenProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 30.01.2025.
//

import Foundation

// MARK: - PhoneVisibilityScreenProtocols
protocol PhoneVisibilityScreenBusinessLogic {
    /// потом нужно сделать, чтобы параметр был не стринг, а ConfidentialityDetails,
    /// который касается изменения видимости номера телефона
    /// чуть подробнее расписал в интеракторе, где имплементированна функция.
    func backToConfidentialityScreen(_ phoneRestriction: String)
    
    func loadUserRestrictions()
    func showUserRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData)
    func saveNewRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData)
}

protocol PhoneVisibilityScreenPresentationLogic {
    func showUserRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData)
}

protocol PhoneVisibilityScreenWorkerLogic {
    func updateUserRestriction(_ request: ConfidentialitySettingsModels.ConfidentialityUserData,
                               completion: @escaping (Result<ConfidentialitySettingsModels.ConfidentialityUserData, Error>) -> Void)
    func saveNewRestrictions(_ newUserRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData)
}
