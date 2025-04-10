//
//  RegistrationInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.01.2025.
//

import Foundation
import OSLog

// MARK: - SendCodeInteractor
class SendCodeInteractor: SendCodeBusinessLogic {

    // MARK: - Properties
    private let presenter: SendCodePresentationLogic
    private let errorHandler: ErrorHandlerLogic
    private let logger: OSLog

    var onRouteToVerifyScreen: ((String) -> Void)?
    
    // MARK: - Initialization
    init(presenter: SendCodePresentationLogic,
         errorHandler: ErrorHandlerLogic,
         logger: OSLog
    ) {
        self.presenter = presenter
        self.errorHandler = errorHandler
        self.logger = logger
    }
    
    func routeToVerifyScreen(_ phone: String) {
        onRouteToVerifyScreen?(phone)
    }
}
