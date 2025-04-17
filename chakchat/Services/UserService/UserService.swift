//
//  MeService.swift
//  chakchat
//
//  Created by Кирилл Исаев on 12.02.2025.
//

import Foundation
import Combine

// MARK: - UserService
/// пока что здесь закомменчены настоящие реализации запроса к серверу и работают только стабы
final class UserService: UserServiceProtocol {
 
    func sendGetUserRequest(_ userID: UUID, _ accessToken: String, completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.ProfileUserData>, any Error>) -> Void) {
        let endpoint = "\(UserServiceEndpoints.user.rawValue)\(userID)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .get, headers: headers, completion: completion)
    }
    
    func sendCheckUsernameRequest(_ username: String, completion: @escaping (Result<SuccessResponse<SignupModels.UserExistsResponse>, any Error>) -> Void) {
        let endpoint = "\(UserServiceEndpoints.usernameAvailability.rawValue)\(username)"
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .get, headers: headers, completion: completion)
    }
    
    func sendGetMeRequest(_ accessToken: String, completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.ProfileUserData>, any Error>) -> Void) {
        let endpoint = UserServiceEndpoints.me.rawValue
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .get, headers: headers, completion: completion)
    }
    
    func sendPutMeRequest(_ request: ProfileSettingsModels.ChangeableProfileUserData,
                          _ accessToken: String,
                          completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.ProfileUserData>, any Error>) -> Void) {
        let endpoint = UserServiceEndpoints.me.rawValue
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .put, headers: headers, body: body, completion: completion)

    }
    
    func sendGetRestrictionRequest(_ accessToken: String,
                                   completion: @escaping (Result<SuccessResponse<ConfidentialitySettingsModels.ConfidentialityUserData>, any Error>) -> Void) {
        let endpoint = UserServiceEndpoints.meRestrictions.rawValue
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .get, headers: headers, completion: completion)
    }
    
    func sendPutRestrictionRequest(_ request: ConfidentialitySettingsModels.ConfidentialityUserData,
                                   _ accessToken: String,
                                   completion: @escaping (Result<SuccessResponse<ConfidentialitySettingsModels.ConfidentialityUserData>, any Error>) -> Void) {
        let endpoint = UserServiceEndpoints.meRestrictions.rawValue
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .put, headers: headers, body: body, completion: completion)
    }
    
    func sendGetUsersRequest(_ name: String?, _ username: String?, _ page: Int, _ limit: Int, _ accessToken: String, completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.Users>, any Error>) -> Void) {
        let endpoint = UserServiceEndpoints.users.rawValue
        var components = URLComponents(string: endpoint)
        var queryItems: [URLQueryItem] = []
        if let name = name {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        if let username = username {
            queryItems.append(URLQueryItem(name: "username", value: username))
        }
        queryItems.append(URLQueryItem(name: "page", value: String(page)))
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let endpointWithQuery = url.absoluteString
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        print(endpointWithQuery)
        Sender.send(endpoint: endpointWithQuery, method: .get, headers: headers, completion: completion)
    }
    /// нужен для поиска по username в бд, чтобы понимать, может ли пользователь использовать такой username или нет
    /// пока что сделал стаб, в дальнейшем должно работать нормально
    /// в текущий момент если пользователь пытается поставить username = eusername, что
    /// идеалогически означает existing username, то ему выдается информация про этого пользователя,
    /// т е ответ 200.
    /// в противном случае ему вылетает ошибка userNotFound.
    /// валидатор нужен чтобы проверять, не ввел ли пользователь некорректный username
    func sendGetUsernameRequest(_ username: String, _ accessToken: String, completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.ProfileUserData>, any Error>) -> Void) {
        let endpoint = "\(UserServiceEndpoints.username.rawValue)\(username)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .get, headers: headers, completion: completion)
    }
    
    func sendPutPhotoRequest(_ request: ProfileSettingsModels.NewPhotoRequest, _ accessToken: String, completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.ProfileUserData>, any Error>) -> Void) {
        let endpoint = UserServiceEndpoints.photo.rawValue

        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .put, headers: headers, body: body, completion: completion)
    }
    
    func sendDeletePhotoRequest(_ accessToken: String, completion: @escaping (Result<SuccessResponse<ProfileSettingsModels.ProfileUserData>, any Error>) -> Void) {
        let endpoint = UserServiceEndpoints.photo.rawValue
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .delete, headers: headers, completion: completion)
    }
    
    func sendDeleteMeRequest(_ accessToken: String, completion: @escaping (Result<SuccessResponse<EmptyResponse>, any Error>) -> Void) {
        let endpoint = UserServiceEndpoints.me.rawValue
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .delete, headers: headers, completion: completion)
    }
    
    func DONTSENDIT(completion: @escaping (Result<SuccessResponse<EmptyResponse>, any Error>) -> Void) {
        let endpoint = UserServiceEndpoints.teapot.rawValue
        Sender.send(endpoint: endpoint, method: .get, completion: completion)
    }
}

struct EmptyResponse: Codable {}
