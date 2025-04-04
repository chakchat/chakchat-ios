//
//  WSManager.swift
//  chakchat
//
//  Created by Кирилл Исаев on 04.04.2025.
//

import Foundation

final class WSManager: WSManagerProtocol {
        
    enum Keys {
        static let baseURL = "SERVER_BASE_URL"
    }
    
    private var webSocketTask: URLSessionWebSocketTask?
    var onMessage: ((Message) -> Void)?
    
    init() {
        guard let url = URL(string: "idkmyip") else {
            return
        }
        webSocketTask = URLSession(configuration: .default).webSocketTask(with: url)
    }
    
    func connectToWS() {
        webSocketTask?.resume()
        receiveData()
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
                        self.onMessage?(message)
                    } catch {
                        print("❌ JSON parsing error: \(error)")
                    }
                case .data(let data):
                    print("⚠️ Unexpected binary data received: \(data)")
                    break
                @unknown default:
                    debugPrint("Unknown message")
                    break
                }
            case .failure(let failure):
                print(failure)
            }
            
            self.receiveData()
        }
    }
}
