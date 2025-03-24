//
//  AddUserProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.03.2025.
//

import Foundation

protocol AddUserBusinessLogic: SearchInteractor {
    func loadData()
    
    func handleError(_ error: Error)
}

protocol AddUserPresentationLogic {
    func loadData(_ users: [ProfileSettingsModels.ProfileUserData])
}

protocol AddUserWorkerLogic {
    
    func loadUsers(completion: @escaping ([ProfileSettingsModels.ProfileUserData]?) -> Void)
    
    func fetchUsers(
        _ name: String?,
        _ username: String?,
        _ offset: Int,
        _ limit: Int,
        completion: @escaping (Result<ProfileSettingsModels.Users, Error>) -> Void
    )
}
