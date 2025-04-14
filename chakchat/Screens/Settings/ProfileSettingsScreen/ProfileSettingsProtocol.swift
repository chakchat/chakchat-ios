//
//  ProfileSettingsProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.01.2025.
//

import UIKit
import Combine
/// параметр имеет префикс temp => это вынужденная мера для решения проблем со стабами
/// потом этого параметра не будет
// MARK: - ProfileSettings Protocol
protocol ProfileSettingsScreenBusinessLogic {
    func backToSettingsMenu()
    func putNewData(_ newUserData: ProfileSettingsModels.ChangeableProfileUserData)
  
    func loadUserData()
    func showUserData(_ userData: ProfileSettingsModels.ProfileUserData)
    func checkUsername(_ username: String,
                       completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, Error>) -> Void)
    func putProfilePhoto(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteProfilePhoto()
}

protocol ProfileSettingsScreenPresentationLogic {
    func showUserData(_ userData: ProfileSettingsModels.ProfileUserData)
    func deleteImage()
}

protocol ProfileSettingsScreenWorkerLogic {
    func putUserData(_ request: ProfileSettingsModels.ChangeableProfileUserData, completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, Error>) -> Void)
    func getUserData() -> ProfileSettingsModels.ProfileUserData
    func checkUsername(_ username: String, completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, Error>) -> Void)
    
    
    func uploadImage(_ fileData: Data,
                     _ fileName: String,
                     _ mimeType: String,
                     completion: @escaping (Result<SuccessModels.UploadResponse, Error>) -> Void)
    func putProfilePhoto(_ photoID: UUID, completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, Error>) -> Void)
    func deleteProfilePhoto(completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, Error>) -> Void)
}
