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
        .responseDecodable(of: SuccessResponse<Updates>.self) { response in
            if let data = response.data {
                let responseString = String(data: data, encoding: .utf8)
                print("Response as String:", responseString ?? "Failed to decode")
            }
            switch response.result {
            case .success(let model):
                print(model)
                completion(.success(model.data))
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }
}
