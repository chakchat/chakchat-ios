//
//  VerificationService.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.01.2025.
//

import Foundation
import UIKit
final class VerificationService: VerificationServiceLogic {
        
    func send(_ request: Verify.VerifyCodeRequest,
              completion: @escaping (Result<Verify.SuccessVerifyResponse, APIError>) -> Void) {
        print("Send request to server")
        let signupKey = request.signupKey
        let code = request.code
        
        guard let url = URL(string: SignupEndpoints.verifyCodeEndpoint.rawValue) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //request.addValue(UUID().uuidString, forHTTPHeaderField: "Idempotency-Key")
        
        let body = Verify.VerifyCodeRequest(signupKey: signupKey,
                                            code: code)
        
        guard let httpBody = try? JSONEncoder().encode(body) else {
            completion(.failure(APIError.invalidRequest))
            return
        }
        
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(APIError.networkError(error)))
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
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let responseData = try JSONDecoder().decode(Verify.SuccessVerifyResponse.self, from: data)
                    completion(.success(responseData))
                } catch {
                    completion(.failure(APIError.decodingError(error)))
                }
            default:
                do {
                    let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: data)
                    completion(.failure(APIError.apiError(errorResponse)))
                } catch {
                    completion(.failure(APIError.unknown))
                }
            }
        }
        
        task.resume()
    }
}
