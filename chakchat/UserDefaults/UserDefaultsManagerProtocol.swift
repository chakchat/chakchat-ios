//
//  UserDefaultsManagerProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.01.2025.
//

import Foundation
import UIKit

// MARK: - UserDefaultsManagerProtocol
protocol UserDefaultsManagerProtocol {
    
    func saveId(_ id: UUID)
    func saveUserData(_ userData: ProfileSettingsModels.ProfileUserData)
    func saveNickname(_ nickname: String)
    func saveUsername(_ username: String)
    func savePhone(_ phone: String)
    func saveBirth(_ birth: String?)
    func saveCreatedTime(_ creadetAt: Date)
    func saveOnlineStatus(_ online: String)
    func saveRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData)
    func saveGeneralNotificationStatus(_ generalNotificationStatus: Bool)
    func saveAudioNotificationStatus(_ audioNotificationStatus: Bool)
    func saveVibrationNotificationStatus(_ visualNotificationStatus: Bool)
    
    func savePhotoURL(_ url: URL?)
    func savePhotoMetadata(_ photo: SuccessModels.UploadResponse)
    
    func loadID() -> UUID
    func loadUserData() -> ProfileSettingsModels.ProfileUserData
    func loadNickname() -> String
    func loadUsername() -> String
    func loadPhone() -> String
    func loadBirth() -> String?
    func loadCreatedTime() -> Date
    func loadOnlineStatus() -> String
    func loadRestrictions() -> ConfidentialitySettingsModels.ConfidentialityUserData
    func loadGeneralNotificationStatus() -> Bool
    func loadAudioNotificationStatus() -> Bool
    func loadVibrationNotificationStatus() -> Bool
    
    func loadPhotoURL() -> URL?
    func loadPhotoMetadata() -> SuccessModels.UploadResponse?
    
    func deleteBirth()
    func deletePhotoPath()
}
