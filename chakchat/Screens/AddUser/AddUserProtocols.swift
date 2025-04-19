//
//  AddUserProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.03.2025.
//

import Foundation

protocol AddUserBusinessLogic: SearchInteractor {
    func handleError(_ error: Error)
    func loadCoreDataUsers(completion: @escaping ([ProfileSettingsModels.ProfileUserData]?) -> Void)
    func loadSelectedUsers(completion: @escaping ([ProfileSettingsModels.ProfileUserData]?) -> Void)
}

protocol AddUserPresentationLogic {
}

protocol AddUserWorkerLogic {
    
    func loadCoreDataUsers(completion: @escaping ([ProfileSettingsModels.ProfileUserData]?) -> Void)
    func loadSelectedUsers(completion: @escaping ([ProfileSettingsModels.ProfileUserData]?) -> Void)
    
    func fetchUsers(
        _ name: String?,
        _ username: String?,
        _ offset: Int,
        _ limit: Int,
        completion: @escaping (Result<ProfileSettingsModels.Users, Error>) -> Void
    )
}
