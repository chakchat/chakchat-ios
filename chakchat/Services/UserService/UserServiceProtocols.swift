//
//  MeServiceProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 12.02.2025.
//

import Foundation
import Combine

protocol UserServiceProtocol {
    func sendGetUserRequest(_ userID: UUID, _ accessToken: String, completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.ProfileUserData>, Error>) -> Void)
    
    func sendGetUsersRequest(_ name: String?, _ username: String?, _ page: Int, _ limit: Int, _ accessToken: String, completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.Users>, any Error>) -> Void)
    
    func sendGetUsernameRequest(_ username: String, _ accessToken: String, completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.ProfileUserData>, any Error>) -> Void)
    
    func sendGetMeRequest(_ accessToken: String, completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.ProfileUserData>, Error>) -> Void)
    
    func sendPutMeRequest(_ request: ProfileSettingsModels.ChangeableProfileUserData,
                          _ accessToken: String,
                          completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.ProfileUserData>, Error>) -> Void)
    
    func sendPutPhotoRequest(_ request: ProfileSettingsModels.NewPhotoRequest,
                             _ accessToken: String,
                             completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.ProfileUserData>, Error>) -> Void)
    
    func sendDeletePhotoRequest(_ accessToken: String,
                                completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.ProfileUserData>, Error>) -> Void)
    
    func sendGetRestrictionRequest(_ accessToken: String,
                                   completion: @escaping (Result<SuccessResponse<ConfidentialitySettingsModels.ConfidentialityUserData>, Error>) -> Void)
    
    func sendPutRestrictionRequest(_ request: ConfidentialitySettingsModels.ConfidentialityUserData,
                                   _ accessToken: String,
                                   completion: @escaping (Result<SuccessResponse<EmptyResponse>, Error>) -> Void)
    
    func DONTSENDIT(completion: @escaping (Result<SuccessResponse<EmptyResponse>, Error>) -> Void)
}

