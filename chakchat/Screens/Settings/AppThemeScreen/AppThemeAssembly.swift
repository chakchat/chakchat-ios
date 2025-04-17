//
//  AppThemeAssembly.swift
//  chakchat
//
//  Created by лизо4ка курунок on 22.02.2025.
//

import UIKit

// MARK: - AppThemeAssembly
enum AppThemeAssembly {
    
    static func build(with context: MainAppContextProtocol) -> UIViewController {
        let presenter = AppThemePresenter()
        let interactor = AppThemeInteractor(presenter: presenter)
        interactor.onRouteToSettingsMenu = {
            AppCoordinator.shared.popScreen()
        }
        let view = AppThemeViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
