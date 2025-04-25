//
//  ContextsProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 05.02.2025.
//

import Foundation
import OSLog

// MARK: - ContextsProtocols
protocol CommonContextProtocol: AnyObject {
    var keychainManager: KeychainManagerBusinessLogic { get }
    var errorHandler: ErrorHandlerLogic { get }
    var userDefaultsManager: UserDefaultsManagerProtocol { get }
    var logger: OSLog { get }
}

protocol SignupContextProtocol: AnyObject, CommonContextProtocol {
    var state: SignupState { get set }
}

protocol MainAppContextProtocol: AnyObject, CommonContextProtocol {
    var eventManager: (EventPublisherProtocol & EventSubscriberProtocol) { get }
    var coreDataManager: CoreDataManagerProtocol { get }
    var state: AppState { get set }
    var wsManager: WSManagerProtocol { get set }
}

