//
//  RegistrationWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.01.2025.
//

import Foundation

// MARK: - SendCodeWorker
final class SendCodeWorker: SendCodeWorkerLogic {
    
    // MARK: - Properties
    private let sendCodeService: SendCodeServiceLogic
    private let keychainManager: KeychainManagerBusinessLogic
    private let userDefaultsManager: UserDefaultsManagerProtocol
    
    init(sendCodeService: SendCodeServiceLogic, keychainManager: KeychainManagerBusinessLogic, userDefaultsManager: UserDefaultsManagerProtocol) {
        self.sendCodeService = sendCodeService
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
    }
    
    // MARK: - Authentication Requests
    func sendInRequest(_ request: SendCodeModels.SendCodeRequest,
                     completion: @escaping (Result<AppState, Error>) -> Void) {
        print("Send request to service")
        sendCodeService.sendCodeRequest(request,
                                        SigninEndpoints.sendPhoneCodeEndpoint.rawValue,
                                        SuccessModels.SendCodeSigninData.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {return}
                switch result {
                case .success(let successResponse):
                    let isSaved = self.keychainManager.save(key: KeychainManager.keyForSaveSigninCode,
                                                       value: successResponse.signinKey)
                    if isSaved {
                        self.userDefaultsManager.savePhone(request.phone)
                        completion(.success(AppState.signin))
                    } else {
                        completion(.failure(Keychain.KeychainError.saveError))
                    }
                case .failure(let apiError):
                    if apiError is APIErrorResponse {
                        guard let apiErrorResponse = apiError as? APIErrorResponse else { return }
                        if apiErrorResponse.errorType == ApiErrorType.userNotFound.rawValue {
                            self.sendUpRequest(request, completion: completion)
                        } else {
                            completion(.failure(apiErrorResponse))
                        }
                    } else {
                        completion(.failure(apiError))
                    }
                }
            }
        }
    }
    
    // MARK: - Registration Requests
    func sendUpRequest(_ request: SendCodeModels.SendCodeRequest,
                       completion: @escaping (Result<AppState, Error>) -> Void) {
        sendCodeService.sendCodeRequest(request,
                                        SignupEndpoints.sendPhoneCodeEndpoint.rawValue,
                                        SuccessModels.SendCodeSignupData.self) { [weak self]result in
            DispatchQueue.main.async {
                guard let self = self else {return}
                switch result {
                case .success(let successResponse):
                    let isSaved = self.keychainManager.save(key: KeychainManager.keyForSaveSignupCode,
                                                       value: successResponse.signupKey)
                    if isSaved {
                        self.userDefaultsManager.savePhone(request.phone)
                        completion(.success(AppState.signupVerifyCode))
                    } else {
                        completion(.failure(Keychain.KeychainError.saveError))
                    }
                case .failure(let apiError):
                    completion(.failure(apiError))
                }
            }
        }
    }
}
