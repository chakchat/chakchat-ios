//
//  StartAssembly.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.01.2025.
//

import Foundation
import UIKit

// MARK: - StartAssembly
enum StartAssembly {
    
    static func build(with context: SignupContextProtocol, coordinator: AppCoordinator) -> UIViewController{
        let view = StartViewController()
        
        view.onRouteToSendCodeScreen = { [weak context, weak coordinator] state in
            context?.state = state
            print(state)
            coordinator?.showRegistrationScreen()
        }
        
        return view
    }
}
