//
//  ErrorHandler.swift
//  chakchat
//
//  Created by Кирилл Исаев on 12.01.2025.
//

import Foundation

// MARK: - ErrorHandler
final class ErrorHandler: ErrorHandlerLogic {
    
    // MARK: - Constants
    private let serverErrorMessage: String = "Server error."
    private let keychainManager: KeychainManagerBusinessLogic
    private let identityService: IdentityServiceProtocol
    
    init(keychainManager: KeychainManagerBusinessLogic, identityService: IdentityServiceProtocol) {
        self.keychainManager = keychainManager
        self.identityService = identityService
    }
    
    func handleError(_ error: Error) -> ErrorId {
        if error is Keychain.KeychainError {
            guard let keychainError = error as? Keychain.KeychainError else {
                print("Error: Cant handle keychain error")
                return ErrorId(message: nil, type: ErrorOutput.None)
            }
            return handleKeychainError(keychainError)
        }
        
        if error is APIError {
            guard let apiError = error as? APIError else {
                print("Error: Cant handle api error ")
                return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            }
            return handleApiError(apiError)
        }
        
        if error is APIErrorResponse {
            guard let apiErrorResponse = error as? APIErrorResponse else {
                print("Error: Cant handle api error response")
                return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            }
            return handleApiResponseError(apiErrorResponse)
        }
        return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
    }
    
    func handleRefreshTokenError() {
        ImageCacheManager.shared.clearCache()
        _ = keychainManager.deleteTokens()
        // TODO: go to sendcodeScreen
    }
    
    private func handleAccessTokenAbsence() {
        guard let refreshToken = keychainManager.getString(key: KeychainManager.keyForSaveRefreshToken) else { return }
        identityService.sendRefreshTokensRequest(RefreshRequest(refreshToken: refreshToken)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let keys):
                _ = self.keychainManager.save(key: KeychainManager.keyForSaveAccessToken, value: keys.data.accessToken)
                _ = self.keychainManager.save(key: KeychainManager.keyForSaveRefreshToken, value: keys.data.refreshToken)
            case .failure(let failure):
                _ = handleError(failure)
            }
        }
    }
    
    // MARK: - Supporting Methods
    private func handleKeychainError(_ keychainError: Keychain.KeychainError) -> ErrorId {
        switch keychainError {
        case Keychain.KeychainError.saveError:
            print("Error: Saving in keychain storage error")
            
        case Keychain.KeychainError.getError:
            print("Error: Getting from keychain storage error")
            
        case Keychain.KeychainError.deleteError:
            print("Error: Deleting from keychain storage error")
        }
        return ErrorId(message: nil, type: ErrorOutput.None)
    }
    
    private func handleApiError(_ apiError: APIError) -> ErrorId {
        switch apiError {
        case .invalidURL:
            print("Error: The URL is invalid.")
            
        case .invalidRequest:
            print("Error: The request is invalid.")
            
        case .networkError(let underlyingError):
            print("Error: Network error occurred. Details: \(underlyingError.localizedDescription)")
            
        case .invalidResponse:
            print("Error: Received an invalid response from the server.")
            
        case .noData:
            print("Error: No data received from the server.")
            
        case .decodingError(let decodingError):
            print("Error: Failed to decode the response. Details: \(decodingError.localizedDescription)")
            
        case .unknown:
            print("Error: An unknown error occurred.")
        }
        return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
    }
    
    private func handleApiResponseError(_ apiResponseError: APIErrorResponse) -> ErrorId {
        switch apiResponseError.errorType {
        case ApiErrorType.internalError.rawValue:
            print("Error: Internal server error.")
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            
        case ApiErrorType.invalidJson.rawValue:
            print("Error: Invalid JSON received.")
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
        case ApiErrorType.validationFailed.rawValue:
            if let details = apiResponseError.errorDetails {
                let detailMessages = details.map { "\($0.field): \($0.message)" }.joined(separator: "\n")
                print("Error: Validation failed:\n\(detailMessages)")
            } else {
                print("Error: Validation failed.")
            }
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            
        case ApiErrorType.userNotFound.rawValue:
            print("Error: User not found.")
            return ErrorId(message: nil, type: ErrorOutput.None)
            
        case ApiErrorType.idempotencyKeyMissing.rawValue:
            print("Error: Idempotency key is missing.")
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            
        case ApiErrorType.sendCodeFreqExceeded.rawValue:
            print("Error: Too many requests. Please wait before retrying.")
            return ErrorId(message: "You are requesting a code too often", type: ErrorOutput.DisappearingLabel)
            
        case ApiErrorType.signinKeyNotFound.rawValue:
            print("Error: Sign-in key not found.")
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            
        case ApiErrorType.wrongCode.rawValue:
            print("Error: Incorrect code entered.")
            return ErrorId(message: "Incorrect code", type: ErrorOutput.DisappearingLabel)
            
        case ApiErrorType.refreshTokenExpired.rawValue:
            print("Error: Session expired. Please log in again.")
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            
        case ApiErrorType.refreshTokenInvalidated.rawValue:
            print("Error: Session invalidated. Please log in again.")
            handleRefreshTokenError()
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            
        case ApiErrorType.invalidToken.rawValue:
            print("Error: Invalid token provided.")
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            
        case ApiErrorType.invalidTokenType.rawValue:
            print("Error: Token type is invalid.")
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            
        case ApiErrorType.unauthorized.rawValue:
            print("Error: Unauthorized access.")
            //handleAccessTokenAbsence()
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            
        case ApiErrorType.accessTokenExpired.rawValue:
            print("Error: Access token expired.")
            //handleAccessTokenAbsence()
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            
        case ApiErrorType.notFound.rawValue:
            print("Error: Requested resource not found.")
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            
        case ApiErrorType.userAlreadyExists.rawValue:
            print("Error: User already exists.")
            return ErrorId(message: nil, type: ErrorOutput.None)
            
        case ApiErrorType.signupKeyNotFound.rawValue:
            print("Error: Sign-up key not found.")
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
            
        case ApiErrorType.usernameAlreadyExists.rawValue:
            print("Error: Username is already taken.")
            return ErrorId(message: "User with this nickname already exists", type: ErrorOutput.DisappearingLabel)
            
        default:
            print("Error: An unknown error occurred.")
            return ErrorId(message: serverErrorMessage, type: ErrorOutput.Alert)
        }
    }
}


