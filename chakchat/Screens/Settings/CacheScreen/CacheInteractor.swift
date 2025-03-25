//
//  CacheInteractor.swift
//  chakchat
//
//  Created by лизо4ка курунок on 23.02.2025.
//

import Foundation

// MARK: - CacheInteractor
final class CacheInteractor: CacheBusinessLogic {
        
    // MARK: - Properties
    private let presenter: CachePresentationLogic
    var onRouteToSettingsMenu: (() -> Void)?
    
    // MARK: - Initialization
    init(presenter: CachePresentationLogic) {
        self.presenter = presenter
    }
        
    // MARK: - Routing
    func backToSettingsMenu() {
        onRouteToSettingsMenu?()
    }
}
