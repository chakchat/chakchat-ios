//
//  AddUserInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.03.2025.
//

import Foundation
import OSLog

final class AddUserInteractor: AddUserBusinessLogic {
        
    private let presenter: AddUserPresentationLogic
    private let worker: AddUserWorkerLogic
    private let errorHandler: ErrorHandlerLogic
    private let logger: OSLog
    
    init(
        presenter: AddUserPresentationLogic,
        worker: AddUserWorkerLogic,
        errorHandler: ErrorHandlerLogic,
        logger: OSLog
    ) {
        self.presenter = presenter
        self.worker = worker
        self.errorHandler = errorHandler
        self.logger = logger
    }
    
    func fetchUsers(_ name: String?, _ username: String?, _ page: Int, _ limit: Int, completion: @escaping (Result<ProfileSettingsModels.Users, any Error>) -> Void) {
        worker.fetchUsers(name, username, page, limit) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                os_log("Fetched users", log: self.logger, type: .default)
                completion(.success(data))
            case .failure(let failure):
                os_log("Failed to fetch users", log: self.logger, type: .fault)
                completion(.failure(failure))
            }
        }
    }

    
    func handleError(_ error: Error) {
        _ = errorHandler.handleError(error)
        print(error)
    }
    
    func loadCoreDataUsers(completion: @escaping ([ProfileSettingsModels.ProfileUserData]?) -> Void) {
        worker.loadCoreDataUsers() { users in
            completion(users)
        }
    }
    
    func loadSelectedUsers(completion: @escaping ([ProfileSettingsModels.ProfileUserData]?) -> Void) {
        worker.loadSelectedUsers() { users in
            completion(users)
        }
    }
}
