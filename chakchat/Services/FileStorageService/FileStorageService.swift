//
//  FileStorageService.swift
//  chakchat
//
//  Created by лизо4ка курунок on 16.02.2025.
//

import Foundation
import Alamofire

// MARK: - FileStorageService
final class FileStorageService: FileStorageServiceProtocol {
    
    func sendFileUploadRequest(_ fileData: Data, _ fileName: String, _ mimeType: String, _ accessToken: String, completion: @escaping (Result<SuccessResponse<SuccessModels.UploadResponse>, Error>) -> Void) {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: Sender.Keys.baseURL) else {
            fatalError("Can't get baseurl")
        }
        let endpoint = "\(baseURL)\(FileStorageEndpoints.upload.rawValue)"
        let idempotencyKey = UUID().uuidString
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey
        ]
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(Data(fileName.utf8), withName: "file_name")
            multipartFormData.append(Data(mimeType.utf8), withName: "mime_type")
            multipartFormData.append(fileData, withName: "file", fileName: fileName, mimeType: mimeType)
        }, to: endpoint, headers: headers)
        .validate()
        .responseDecodable(of: SuccessResponse<SuccessModels.UploadResponse>.self) { response in
            print("Response: \(response)")
            if let statusCode = response.response?.statusCode {
                print("Status code: \(statusCode)")
            }
            if let headers = response.response?.headers {
                print("Headers: \(headers)")
            }
            
            // Логирование тела ответа
            if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                print("Server response: \(responseString)")
            }
            switch response.result {
            case .success(let responseData):
                completion(.success(responseData))
            case .failure:
                if let data = response.data {
                    do {
                        let apiErrorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: data)
                        completion(.failure(APIErrorResponse(errorType: apiErrorResponse.errorType, errorMessage: apiErrorResponse.errorMessage, errorDetails: apiErrorResponse.errorDetails)))
                    } catch {
                        completion(.failure(APIError.decodingError(error)))
                    }
                } else {
                    completion(.failure(APIError.noData))
                }
            }
        }
    }
    
    func sendFileUploadInitRequest(_ request: FileStorageRequest.UploadInit, _ accessToken: String, completion: @escaping (Result<SuccessResponse<SuccessModels.UploadInitResponse>, any Error>) -> Void) {
        let endpoint = FileStorageEndpoints.uploadMultipartInit.rawValue
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
    
    func sendFileUploadPartRequest(_ partNumber: Int, _ uploadID: UUID, _ fileURL: URL, _ accessToken: String, completion: @escaping (Result<SuccessResponse<SuccessModels.UploadPartResponse>, any Error>) -> Void) {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: Sender.Keys.baseURL) else {
            fatalError("Can't get baseurl")
        }
        let endpoint = "\(baseURL)\(FileStorageEndpoints.uploadMultipartPart.rawValue)"
        let idempotencyKey = UUID().uuidString
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey
        ]
        
        guard let fileData = try? Data(contentsOf: fileURL) else {
            return
        }
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(Data(String(partNumber).utf8), withName: "part_number")
            multipartFormData.append(Data(uploadID.uuidString.utf8), withName: "upload_id")
            multipartFormData.append(fileData, withName: "file")
        }, to: endpoint, headers: headers)
        .validate()
        .responseDecodable(of: SuccessResponse<SuccessModels.UploadPartResponse>.self) { response in
            print("Response: \(response)")
            if let statusCode = response.response?.statusCode {
                print("Status code: \(statusCode)")
            }
            if let headers = response.response?.headers {
                print("Headers: \(headers)")
            }
            
            // Логирование тела ответа
            if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                print("Server response: \(responseString)")
            }
            switch response.result {
            case .success(let responseData):
                completion(.success(responseData))
            case .failure:
                if let data = response.data {
                    do {
                        let apiErrorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: data)
                        completion(.failure(APIErrorResponse(errorType: apiErrorResponse.errorType, errorMessage: apiErrorResponse.errorMessage, errorDetails: apiErrorResponse.errorDetails)))
                    } catch {
                        completion(.failure(APIError.decodingError(error)))
                    }
                } else {
                    completion(.failure(APIError.noData))
                }
            }
        }
    }
    
    func sendFileUploadAbortRequest(_ request: FileStorageRequest.UploadAbort, _ accessToken: String, completion: @escaping (Result<SuccessResponse<SuccessModels.EmptyResponse>, any Error>) -> Void) {
        let endpoint = FileStorageEndpoints.uploadMultipartAbort.rawValue
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .put, headers: headers, body: body, completion: completion)
    }
    
    func sendFileUploadCompleteRequest(_ request: FileStorageRequest.UploadComplete, _ accessToken: String, completion: @escaping (Result<SuccessResponse<SuccessModels.UploadResponse>, any Error>) -> Void) {
        let endpoint = FileStorageEndpoints.uploadMultipartComplete.rawValue
        let idempotencyKey = UUID().uuidString
        
        let body = try? JSONEncoder().encode(request)
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Idempotency-Key": idempotencyKey,
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .post, headers: headers, body: body, completion: completion)
    }
    
    func sendGetFileRequest(_ fileID: UUID, _ accessToken: String, completion: @escaping (Result<SuccessResponse<SuccessModels.UploadResponse>, any Error>) -> Void) {
        let endpoint = "\(FileStorageEndpoints.getFileMetadata.rawValue)\(fileID)"
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        Sender.send(endpoint: endpoint, method: .get, headers: headers, completion: completion)
    }
}

// MARK: - Models
enum FileStorageRequest {
    struct UploadInit: Codable {
        let fileName: String
        let mimeType: String
        
        enum CodingKeys: String, CodingKey {
            case fileName = "file_name"
            case mimeType = "mime_type"
        }
    }

    struct UploadAbort: Codable {
        let uploadID: String
        
        enum CodingKeys: String, CodingKey {
            case uploadID = "upload_id"
        }
    }

    struct UploadComplete: Codable {
        let uploadID: String
        let parts: [Part]
        
        enum CodingKeys: String, CodingKey {
            case uploadID = "upload_id"
            case parts = "parts"
        }
    }
}

struct Part: Codable {
    let partNumber: Int
    let eTag: String
    
    enum CodingKeys: String, CodingKey {
        case partNumber = "part_number"
        case eTag = "e_tag"
    }
}

