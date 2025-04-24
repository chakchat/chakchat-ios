//
//  VerifyWorker.swift
//  chakchat
//
//  Created by Кирилл Исаев on 08.01.2025.
//

import Foundation

// MARK: - VerifyWorker
final class VerifyWorker: VerifyWorkerLogic {
    
    // MARK: - Properties
    private let identityService: IdentityServiceProtocol
    private let keychainManager: KeychainManagerBusinessLogic
    private let userDefaultsManager: UserDefaultsManagerProtocol
    
    // MARK: - Initialization
    init(
        identityService: IdentityServiceProtocol,
        keychainManager: KeychainManagerBusinessLogic,
        userDefaultsManager: UserDefaultsManagerProtocol
    ) {
        self.identityService = identityService
        self.keychainManager = keychainManager
        self.userDefaultsManager = userDefaultsManager
    }
    
    // MARK: - Public Methods
    func sendInRequest(_ request: SendCodeModels.SendCodeRequest,
                       completion: @escaping (Result<SignupState, Error>) -> Void) {
        print("Send request to service")
        identityService.sendCodeRequest(request,
                                        IdentityServiceEndpoints.signinCodeEndpoint.rawValue,
                                        SuccessModels.SendCodeSigninData.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {return}
                switch result {
                case .success(let successResponse):
                    let isSaved = self.keychainManager.save(key: KeychainManager.keyForSaveSigninCode,
                                                            value: successResponse.data.signinKey)
                    if isSaved {
                        self.userDefaultsManager.savePhone(request.phone)
                        completion(.success(SignupState.signin))
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
    
    func sendUpRequest(_ request: SendCodeModels.SendCodeRequest,
                       completion: @escaping (Result<SignupState, Error>) -> Void) {
        identityService.sendCodeRequest(request,
                                        IdentityServiceEndpoints.signupCodeEndpoint.rawValue,
                                        SuccessModels.SendCodeSignupData.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {return}
                switch result {
                case .success(let successResponse):
                    let isSaved = self.keychainManager.save(key: KeychainManager.keyForSaveSignupCode,
                                                            value: successResponse.data.signupKey)
                    if isSaved {
                        self.userDefaultsManager.savePhone(request.phone)
                        completion(.success(SignupState.signupVerifyCode))
                    } else {
                        completion(.failure(Keychain.KeychainError.saveError))
                    }
                case .failure(let apiError):
                    completion(.failure(apiError))
                }
            }
        }
    }
    
    func sendVerificationRequest<Request, Response>(_ request: Request, _ endpoint: String, _ responseType: Response.Type, completion: @escaping (Result<SignupState, any Error>) -> Void) where Request : Decodable, Request : Encodable, Response : Decodable, Response : Encodable {
        print("Send request to service")
        identityService.sendVerificationRequest(
            request,
            endpoint,
            responseType
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {return}
                switch result {
                case .success(let successResponse):
                    guard let successResponse = successResponse.data as? SuccessModels.Tokens else {
                        completion(.success(SignupState.signup))
                        return
                    }
                    self.saveToken(successResponse, completion: completion)
                case .failure(let apiError):
                    completion(.failure(apiError))
                }
            }
        }
    }
    
    func getVerifyCode(_ key: String) -> UUID? {
        guard let savedKey = keychainManager.getUUID(key: key) else {
            return nil
        }
        return savedKey
    }
    
    func saveToken(_ response: SuccessModels.Tokens,
                   completion: @escaping (Result<SignupState, Error>) -> Void) {
        var isSaved = self.keychainManager.save(key: KeychainManager.keyForSaveAccessToken,
                                                value: response.accessToken)
        if !isSaved {
            completion(.failure(Keychain.KeychainError.saveError))
        }
        
        isSaved = self.keychainManager.save(key: KeychainManager.keyForSaveRefreshToken,
                                            value: response.refreshToken)
        if isSaved {
            print("Saved tokens: \nAccess:\(response.accessToken)\nRefresh:\(response.refreshToken)")
            completion(.success(SignupState.onChatsMenu))
        } else {
            completion(.failure(Keychain.KeychainError.saveError))
        }
    }
    
    func getPhone() -> String {
        let phone = userDefaultsManager.loadPhone()
        return phone
    }
    
    func resendInRequest(_ request: VerifyModels.ResendCodeRequest,
                         completion: @escaping (Result<SignupState, Error>) -> Void) {
        print("Send request to service")
        identityService.sendCodeRequest(request,
                                        IdentityServiceEndpoints.signinCodeEndpoint.rawValue,
                                        SuccessModels.SendCodeSigninData.self) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {return}
                switch result {
                case .success(let successResponse):
                    let isSaved = self.keychainManager.save(key: KeychainManager.keyForSaveSigninCode,
                                                            value: successResponse.data.signinKey)
                    if isSaved {
                        completion(.success(SignupState.signin))
                    } else {
                        completion(.failure(Keychain.KeychainError.saveError))
                    }
                case .failure(let apiError):
                    completion(.failure(apiError))
                }
            }
        }
    }
    
    func resendUpRequest(_ request: VerifyModels.ResendCodeRequest,
                         completion: @escaping (Result<SignupState, Error>) -> Void) {
        print("Send request to service")
        identityService.sendCodeRequest(request,
                                        IdentityServiceEndpoints.signupCodeEndpoint.rawValue,
                                        SuccessModels.SendCodeSignupData.self) { [weak self]result in
            DispatchQueue.main.async {
                guard let self = self else {return}
                switch result {
                case .success(let successResponse):
                    let isSaved = self.keychainManager.save(key: KeychainManager.keyForSaveSignupCode,
                                                            value: successResponse.data.signupKey)
                    if isSaved {
                        completion(.success(SignupState.signupVerifyCode))
                    } else {
                        completion(.failure(Keychain.KeychainError.saveError))
                    }
                case .failure(let apiError):
                    completion(.failure(apiError))
                }
            }
        }
    }
    
    func getDeviceToken() -> String? {
        return keychainManager.getString(key: KeychainManager.keyForDeviceToken)
    }
}
