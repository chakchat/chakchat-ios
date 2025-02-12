//
//  MeServiceProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 12.02.2025.
//

import Foundation

protocol MeServiceProtocol {
    func sendGetMeRequest(completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, Error>) -> Void)
    
    func sendPutMeRequest(_ request: ProfileSettingsModels.ChangeableProfileUserData,
                       completion: @escaping (Result<ProfileSettingsModels.ProfileUserData, Error>) -> Void)
}
