//
//  SignupInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.01.2025.
//

import Foundation
import OSLog
import UserNotifications

// MARK: - SignupInteractor
final class SignupInteractor: SignupBusinessLogic {

    // MARK: - Properties
    private let presenter: SignupPresentationLogic
    private let worker: SignupWorkerLogic
    private let errorHandler: ErrorHandlerLogic
    private let state: SignupState
    private let logger: OSLog
    
    var onRouteToChatScreen: ((SignupState) -> Void)?
    
    // MARK: - Initialization
    init(presenter: SignupPresentationLogic,
         worker: SignupWorkerLogic,
         state: SignupState,
         errorHandler: ErrorHandlerLogic,
         logger: OSLog
    ) {
        self.presenter = presenter
        self.worker = worker
        self.state = state
        self.errorHandler = errorHandler
        self.logger = logger
    }
    
    // MARK: - Public Methods
    func sendSignupRequest(_ name: String, _ username: String) {
        os_log("Send signup request to server", log: logger, type: .info)
        guard let signupKey = worker.getSignupCode() else {
            os_log("Can't find signup key in keychain storage", log: logger, type: .fault)
            return
        }
        
        checkNotificationPermission { [weak self] isNotificationsAllowed in
            guard let self = self else { return }
            
            let request: SignupModels.SignupRequest
            if isNotificationsAllowed, let deviceToken = self.worker.getDeviceToken() {
                request = SignupModels.SignupRequest(
                    signupKey: signupKey,
                    name: name,
                    username: username,
                    device: SignupModels.Device(
                        type: "ios",
                        deviceToken: deviceToken
                    )
                )
            } else {
                request = SignupModels.SignupRequest(
                    signupKey: signupKey,
                    name: name,
                    username: username,
                    device: nil
                )
            }
            
            self.worker.sendRequest(request) { [weak self] result in
                guard let self = self else {return}
                switch result {
                case .success(let state):
                    os_log("User registered, saved data", log: logger, type: .info)
                    self.successTransition(state)
                case .failure(let error):
                    let errorId = self.errorHandler.handleError(error)
                    self.presenter.showError(errorId)
                }
            }
        }
    }
    
    func checkUsernameAvailability(_ username: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        worker.checkUsernameAvailability(username) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                os_log("This username is available", log: self.logger, type: .default)
                completion(.success(data.userExists))
            case .failure(let failure):
                os_log("Failed to check username availability", log: self.logger, type: .default)
                _ = self.errorHandler.handleError(failure)
                print(failure)
                completion(.failure(failure))
            }
        }
    }
    
    private func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    completion(true)
                case .denied:
                    completion(false)
                case .notDetermined:
                    completion(false)
                case .ephemeral:
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Routing
    func successTransition(_ state: SignupState) {
        os_log("Routed to chat menu screen", log: logger, type: .default)
        onRouteToChatScreen?(state)
    }
}
