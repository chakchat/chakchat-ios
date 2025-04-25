//
//  WSManager.swift
//  chakchat
//
//  Created by Кирилл Исаев on 04.04.2025.
//

import Foundation
import OSLog

final class WSManager: WSManagerProtocol {
        
    enum Keys {
        static let baseURL = "SERVER_BASE_URL"
    }
    private let keychainManager: KeychainManagerBusinessLogic
    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    var onMessage: ((Message) -> Void)?
    
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let initialReconnectDelay: TimeInterval = 1.0
    private let maxReconnectDelay: TimeInterval = 30.0
    
    init(keychainManager: KeychainManagerBusinessLogic) {
        self.keychainManager = keychainManager
    }
    
    func connectToWS() {
        guard let url = URL(string: "http://test.chakchat.ru/ws") else { return }
        
        var request = URLRequest(url: url)
        guard let accessToken = keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) else { return }
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        webSocketTask = URLSession(configuration: .default).webSocketTask(with: request)
        webSocketTask?.resume()
        receiveData()
        startPinging()
    }
    
    func receiveData() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let success):
                switch success {
                case .string(let text):
                    guard let data = text.data(using: .utf8) else { return }
                    do {
                        let message = try JSONDecoder().decode(Message.self, from: data)
                        let jsonString = String(data: data, encoding: .utf8)
                        print(jsonString as Any)
                        self.onMessage?(message)
                    } catch {
                        print("JSON parsing error: \(error)")
                    }
                case .data(let data):
                    print("Unexpected binary data received: \(data)")
                    break
                @unknown default:
                    debugPrint("Unknown message")
                    break
                }
            case .failure(let failure):
                self.handleConnectionFailure(error: failure)
                return
            }
            
            self.receiveData()
        }
    }
    
    func disconnect() {
        stopPinging()
        webSocketTask?.cancel(with: .goingAway, reason: "Client is not in a mood".data(using: .utf8))
        webSocketTask = nil
    }
    
    private func sendPing() {
        guard webSocketTask?.state == .running else {
            return
        }
        
        webSocketTask?.sendPing { error in
            if let error = error {
                print("Ping error: \(error)")
            } else {
                print("Ping sent successfully")
            }
        }
    }
    
    private func startPinging(interval: TimeInterval = 10) {
        pingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPinging() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func handleConnectionFailure(error: Error) {
        debugPrint("WebSocket connection failed: \(error)")
        disconnect()
        
        guard reconnectAttempts < maxReconnectAttempts else {
            print("Max reconnect attempts reached. Stopping.")
            return
        }
        
        let delay = min(initialReconnectDelay * pow(2, Double(reconnectAttempts)), maxReconnectDelay)
        reconnectAttempts += 1
        
        print("Reconnecting in \(delay) seconds...")
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connectToWS()
        }
    }
}
