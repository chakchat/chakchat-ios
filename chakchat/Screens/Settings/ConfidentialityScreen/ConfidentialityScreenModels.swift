//
//  ConfidentialityScreenModels.swift
//  chakchat
//
//  Created by Кирилл Исаев on 28.01.2025.
//

import Foundation

// MARK: - ConfidentialitySettingsModels
enum ConfidentialitySettingsModels {
    struct ConfidentialityUserData {
        var phoneNumberState: ConfidentialityState
        var dateOfBirthState: ConfidentialityState
        var onlineStatus: ConfidentialityState
    }
}

// MARK: - ConfidentialityState
enum ConfidentialityState: String {
    case all = "All"
    case custom = "Custom"
    case nobody = "Nobody"
}
