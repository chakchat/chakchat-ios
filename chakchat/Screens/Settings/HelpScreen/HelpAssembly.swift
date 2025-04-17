//
//  HelpAssembly.swift
//  chakchat
//
//  Created by лизо4ка курунок on 23.02.2025.
//

import UIKit

// MARK: - HelpAssembly
enum HelpAssembly {
    
    static func build(with context: MainAppContextProtocol) -> UIViewController {
        let presenter = HelpPresenter()
        let interactor = HelpInteractor(presenter: presenter)
        interactor.onRouteToSettingsMenu = {
            AppCoordinator.shared.popScreen()
        }
        let view = HelpViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
