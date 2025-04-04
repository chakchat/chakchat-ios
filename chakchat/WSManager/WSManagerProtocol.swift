//
//  WSManagerProtocol.swift
//  chakchat
//
//  Created by Кирилл Исаев on 04.04.2025.
//

import Foundation

protocol WSManagerProtocol {
    func connectToWS()
    func receiveData()
    func disconnect()
}
