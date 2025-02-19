//
//  UserDefaultsService.swift
//  chakchat
//
//  Created by Кирилл Исаев on 22.01.2025.
//

import Foundation
import UIKit

// MARK: - UserDefaultsManager
final class UserDefaultsManager: UserDefaultsManagerProtocol {
    

    // MARK: - Constants
    private let idKey = "IdKey"
    private let photoKey = "userAvatar"
    private let nicknameKey = "userNickname"
    private let usernameKey = "userUsername"
    private let phoneKey = "userPhone"
    private let birthKey = "birthKey"
    private let onlineKey = "onlineKey"
    private let photoUrlKey = "photoUrlKey"
    private let photoMetadataKey = "photoMetadataKey"
    private let restrictionsKey = "restrictionsKey"
    private let generalNotificationKey = "generalNotification"
    private let audioNotificationKey = "audioNotification"
    private let vibrationNotificationKey = "vibrationNotification"
    
    func saveUserData(_ userData: ProfileSettingsModels.ProfileUserData) {
        saveId(userData.id)
        saveNickname(userData.nickname)
        saveUsername(userData.username)
        savePhone(userData.phone)
        if let photoPath = userData.photo {
            savePhotoURL(photoPath)
        }
        saveBirth(userData.dateOfBirth)
    }
    
    func saveId(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: idKey)
    }
    
    // MARK: - Nickname Saving
    func saveNickname(_ nickname: String) {
        UserDefaults.standard.set(nickname, forKey: nicknameKey)
    }
    
    // MARK: - Username Saving
    func saveUsername(_ username: String) {
        UserDefaults.standard.set(username, forKey: usernameKey)
    }
    
    // MARK: - Phone Saving
    func savePhone(_ phone: String) {
        UserDefaults.standard.set(phone, forKey: phoneKey)
    }
    
    func saveBirth(_ birth: String?) {
        UserDefaults.standard.set(birth, forKey: birthKey)
    }
    
    func saveOnlineStatus(_ online: String) {
        UserDefaults.standard.set(online, forKey: onlineKey)
    }
    
    func saveRestrictions(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData) {
        if let encoded = try? JSONEncoder().encode(userRestrictions) {
            UserDefaults.standard.set(encoded, forKey: restrictionsKey)
        }
    }
    
    func saveGeneralNotificationStatus(_ generalNotificationStatus: Bool) {
        UserDefaults.standard.set(generalNotificationStatus, forKey: generalNotificationKey)
        print("General notification status = \(generalNotificationStatus)")
    }
    
    func saveAudioNotificationStatus(_ audioNotificationStatus: Bool) {
        UserDefaults.standard.set(audioNotificationStatus, forKey: audioNotificationKey)
        print("Audio notification status = \(audioNotificationStatus)")
    }
    
    func saveVibrationNotificationStatus(_ vibrationNotificationStatus: Bool) {
        UserDefaults.standard.set(vibrationNotificationStatus, forKey: vibrationNotificationKey)
        print("Vibration notification status = \(vibrationNotificationStatus)")
    }
    
    func savePhotoURL(_ url: URL) {
        UserDefaults.standard.set(url, forKey: photoUrlKey)
    }
    
    func savePhotoMetadata(_ photo: SuccessModels.UploadResponse) {
        if let encoded = try? JSONEncoder().encode(photo) {
            UserDefaults.standard.set(encoded, forKey: photoMetadataKey)
        }
    }
    
    func loadUserData() -> ProfileSettingsModels.ProfileUserData {
        let id = loadID()
        let nickname = loadNickname()
        let username = loadUsername()
        let phone = loadPhone()
        let dateOfBirth = loadBirth()
        if let photoURL = loadPhotoURL() {
            return ProfileSettingsModels.ProfileUserData(id: id,
                                                         nickname: nickname,
                                                         username: username, phone: phone,
                                                         photo: photoURL,
                                                         dateOfBirth: dateOfBirth)
        }

        return ProfileSettingsModels.ProfileUserData(id: id,
                                                     nickname: nickname,
                                                     username: username,
                                                     phone: phone,
                                                     photo: nil,
                                                     dateOfBirth: dateOfBirth
        )
    }
    
    func loadID() -> UUID {
        guard let idString = UserDefaults.standard.string(forKey: idKey) else {
            return UUID()
        }
        if let id = UUID(uuidString: idString) {
            return id
        }
        return UUID()
    }
    // MARK: - Nickname Loading
    func loadNickname() -> String {
        guard let nickname = UserDefaults.standard.string(forKey: nicknameKey) else {
            return "Default"
        }
        return nickname
    }
    
    // MARK: - Username Loading
    func loadUsername() -> String {
        guard let username = UserDefaults.standard.string(forKey: usernameKey) else {
            return "Default"
        }
        return username
    }
    
    // MARK: - Phone Loading
    func loadPhone() -> String {
        guard let phone = UserDefaults.standard.string(forKey: phoneKey) else {
            return "Default"
        }
        return phone
    }
    
    func loadBirth() -> String? {
        if let birth = UserDefaults.standard.string(forKey: birthKey) {
            return birth
        }
        return nil
    }
    
    func loadOnlineStatus() -> String {
        if let online = UserDefaults.standard.string(forKey: onlineKey) {
            return online
        }
        return "everyone"
    }
    
    func loadRestrictions() -> ConfidentialitySettingsModels.ConfidentialityUserData {
        if let savedData = UserDefaults.standard.data(forKey: restrictionsKey) {
            if let savedRestrictions = try? JSONDecoder().decode(ConfidentialitySettingsModels.ConfidentialityUserData.self,
                                                           from: savedData) {
                return savedRestrictions
            }
        }
        return ConfidentialitySettingsModels.ConfidentialityUserData(phone: ConfidentialityDetails(openTo: "everyone", specifiedUsers: nil), dateOfBirth: ConfidentialityDetails(openTo: "everyone", specifiedUsers: nil))
    }
    
    func loadGeneralNotificationStatus() -> Bool {
        let generalNotificationStatus = UserDefaults.standard.bool(forKey: generalNotificationKey)
        print("General notification status is \(generalNotificationStatus)")
        return generalNotificationStatus
    }
    
    func loadAudioNotificationStatus() -> Bool {
        let audioNotificationStatus = UserDefaults.standard.bool(forKey: audioNotificationKey)
        print("Audio notification status is \(audioNotificationStatus)")
        return audioNotificationStatus
    }
    
    func loadVibrationNotificationStatus() -> Bool {
        let vibrationNotificationStatus = UserDefaults.standard.bool(forKey: vibrationNotificationKey)
        print("Vibration notification status is \(vibrationNotificationStatus)")
        return vibrationNotificationStatus
    }
    
    func loadPhotoURL() -> URL? {
        if let photoPath = UserDefaults.standard.url(forKey: photoUrlKey) {
            return photoPath
        }
        return nil
    }
    
    func loadPhotoMetadata() -> SuccessModels.UploadResponse? {
        if let savedData = UserDefaults.standard.data(forKey: photoMetadataKey) {
            if let decoded = try? JSONDecoder().decode(SuccessModels.UploadResponse.self, from: savedData) {
                return decoded
            }
        }
        return nil
    }
    
    func deleteBirth() {
        UserDefaults.standard.removeObject(forKey: birthKey)
    }
    
    func deletePhotoPath() {
        UserDefaults.standard.removeObject(forKey: photoUrlKey)
    }
}

// MARK: - UserDefaultsError
enum UserDefaultsError: Error {
    case loadError
}
