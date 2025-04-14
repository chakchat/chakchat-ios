//
//  UpdateService.swift
//  chakchat
//
//  Created by Кирилл Исаев on 14.04.2025.
//

import Alamofire
import Foundation

final class UpdateService: UpdateServiceProtocol {
    func getUpdatesInRange(
        _ chatID: UUID,
        _ from: Int64,
        _ to: Int64,
        _ accessToken: String,
        completion: @escaping (Result<Updates, any Error>) -> Void
    ) {
        let endpoint = "http://test.chakchat.ru/api/messaging/v1.0/chat/\(chatID)/update"
        
        let queryParams: [String: Any] = [
            "from": String(from),
            "to": String(to)
        ]
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        AF.request(endpoint,
                   method: .get,
                   parameters: queryParams,
                   encoding: URLEncoding.default,
                   headers: headers)
        .validate()
        .responseDecodable(of: Updates.self) { response in
            switch response.result {
            case .success(let model):
                print(model)
                completion(.success(model))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
