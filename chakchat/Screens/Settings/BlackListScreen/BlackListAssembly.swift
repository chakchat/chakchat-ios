//
//  BlackListAssembly.swift
//  chakchat
//
//  Created by лизо4ка курунок on 24.02.2025.
//

import UIKit

// MARK: - BlackListAssembly
enum BlackListAssembly {
    
    static func build(with context: MainAppContextProtocol) -> UIViewController {
        let presenter = BlackListPresenter()
        let interactor = BlackListInteractor(presenter: presenter)
        interactor.onRouteToConfidantialityScreen = {
            AppCoordinator.shared.popScreen()
        }
        let view = BlackListViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
