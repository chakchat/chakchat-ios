//
//  SenderProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 16.01.2025.
//

import Foundation

// MARK: - SenderLogic
protocol SenderLogic {
    static func Get<T: Codable, U: Codable>(
        requestBody: T?,
        responseType: U.Type,
        endpoint: String,
        completion: @escaping (Result<U, Error>) -> Void
    )
    
    static func Put<T: Codable, U: Codable>(
        requestBody: T,
        responseType: U.Type,
        endpoint: String,
        completion: @escaping (Result<U, Error>) -> Void
    )
    
    static func Post<T: Codable, U: Codable>(
        requestBody: T,
        responseType: U.Type,
        endpoint: String,
        completion: @escaping (Result<U, Error>) -> Void
    )
    
    static func Delete<T: Codable, U: Codable>(
        requestBody: T,
        responseType: U.Type,
        endpoint: String,
        completion: @escaping (Result<U, Error>) -> Void
    )
}
