//
//  Sender.swift
//  chakchat
//
//  Created by Кирилл Исаев on 10.01.2025.
//

import Foundation

// MARK: - Sender
final class Sender: SenderLogic {
    
    enum Keys {
        static let baseURL = "SERVER_BASE_URL"
    }
    
    private static let delays: [TimeInterval] = [1,3,10]
    
    private static let keychainManager: KeychainManagerBusinessLogic = KeychainManager()
    
    static func send<T: Codable>(endpoint: String,
                                 method: HTTPMethod,
                                 headers: [String:String]? = nil,
                                 body: Data? = nil,
                                 attempt: Int = 0,
                                 completion: @escaping (Result<SuccessResponse<T>, Error>) -> Void
    ) {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: Keys.baseURL) else {
            fatalError("Cant get baseURL")
        }
        print("\(baseURL)\(endpoint)")
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        request.httpBody = body
        logRequestBody(body)
        
        sendRequest(request: request, attempt: attempt, endpoint: endpoint, method: method, headers: headers, body: body, completion: completion)
    }
    
    private static func sendRequest<T: Codable>(
        request: URLRequest,
        attempt: Int,
        endpoint: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        completion: @escaping (Result<SuccessResponse<T>, Error>) -> Void
    ) {

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                handleNetworkError(error, attempt: attempt, endpoint: endpoint, method: method, headers: headers, body: body, completion: completion)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            handleResponse(httpResponse, data: data, attempt: attempt, endpoint: endpoint, method: method, headers: headers, body: body, completion: completion)
        }

        task.resume()
    }
    
    private static func handleNetworkError<T: Codable>(
        _ error: Error,
        attempt: Int,
        endpoint: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        completion: @escaping (Result<SuccessResponse<T>, Error>) -> Void
    ) {
        if attempt < delays.count {
            let delay = delays[attempt]
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                send(endpoint: endpoint,
                     method: method,
                     headers: headers,
                     body: body,
                     attempt: attempt + 1,
                     completion: completion)
            }
        } else {
            completion(.failure(APIError.networkError(error)))
        }
    }
    
    private static func handleResponse<T: Codable>(
        _ response: HTTPURLResponse,
        data: Data,
        attempt: Int,
        endpoint: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        completion: @escaping (Result<SuccessResponse<T>, Error>) -> Void
    ) {
        let jsonString = String(data: data, encoding: .utf8)
        print(jsonString as Any)

        switch response.statusCode {
        case 200:
            decodeResponse(data: data, completion: completion)
        case 401:
            handleUnauthorizedError(attempt: attempt, endpoint: endpoint, method: method, headers: headers, body: body, completion: completion)
        case 500...599:
            handleServerError(attempt: attempt, endpoint: endpoint, method: method, headers: headers, body: body, completion: completion, data: data)
        default:
            decodeErrorResponse(data: data, completion: completion)
        }
    }
    
    private static func decodeResponse<T: Codable>(
        data: Data,
        completion: @escaping (Result<SuccessResponse<T>, Error>) -> Void
    ) {
        do {
            let responseData = try JSONDecoder().decode(SuccessResponse<T>.self, from: data)
            completion(.success(responseData))
        } catch {
            completion(.failure(APIError.decodingError(error)))
        }
    }

    private static func handleUnauthorizedError<T: Codable>(
        attempt: Int,
        endpoint: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        completion: @escaping (Result<SuccessResponse<T>, Error>) -> Void
    ) {
        refreshAccessToken { result in
            switch result {
            case .success(let response):
                let tokens = response.data
                saveTokensToKeychain(tokens: tokens)
                send(endpoint: endpoint,
                     method: method,
                     headers: headers,
                     body: body,
                     attempt: attempt + 1,
                     completion: completion)
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    private static func saveTokensToKeychain(tokens: SuccessModels.Tokens) {
        _ = keychainManager.save(key: KeychainManager.keyForSaveAccessToken, value: tokens.accessToken)
        _ = keychainManager.save(key: KeychainManager.keyForSaveRefreshToken, value: tokens.refreshToken)
    }
    
    private static func handleServerError<T: Codable>(
        attempt: Int,
        endpoint: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        completion: @escaping (Result<SuccessResponse<T>, Error>) -> Void,
        data: Data
    ) {
        if attempt < delays.count {
            let delay = delays[attempt]
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                send(endpoint: endpoint,
                     method: method,
                     headers: headers,
                     body: body,
                     attempt: attempt + 1,
                     completion: completion)
            }
        } else {
            decodeErrorResponse(data: data, completion: completion)
        }
    }

    private static func decodeErrorResponse<T: Codable>(
        data: Data,
        completion: @escaping (Result<SuccessResponse<T>, Error>) -> Void
    ) {
        do {
            let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: data)
            completion(.failure(errorResponse))
        } catch {
            completion(.failure(APIError.decodingError(error)))
        }
    }
    
    private static func logRequestBody(_ body: Data?) {
        if let body = body, let stringRequest = String(data: body, encoding: .utf8) {
            print(stringRequest)
        }
    }
    
    private static func refreshAccessToken(completion: @escaping (Result<SuccessResponse<SuccessModels.Tokens>,Error>) -> Void) {
        
        let endpoint = IdentityServiceEndpoints.refreshEndpoint.rawValue
        let idempotencyKey = UUID().uuidString
        
        guard let refreshToken = keychainManager.getString(key: KeychainManager.keyForSaveRefreshToken) else {
            return
        }
        let request = RefreshRequest(refreshToken: refreshToken)
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
}

// MARK: - SuccessResponse
struct SuccessResponse<T: Codable>: Codable {
    let data: T
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
