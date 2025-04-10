//
//  RegistrationProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.01.2025.
//

import Foundation

// MARK: - SendCodeProtocols
protocol SendCodeBusinessLogic {
    func routeToVerifyScreen(_ phone: String)
}

protocol SendCodePresentationLogic {
    func showError(_ error: ErrorId)
}
