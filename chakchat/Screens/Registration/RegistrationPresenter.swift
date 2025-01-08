//
//  RegistrationPresenter.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.01.2025.
//

import Foundation
import UIKit

class RegistrationPresenter: RegistrationPresentationLogic {
    
    weak var view: RegistrationViewController?
    
    func routeToVerifyScreen() {
        view?.navigationController?.pushViewController(VerifyAssembly.build(), animated: true)
    }
    
    func showError(_ error: any Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        view?.present(alert, animated: true, completion: nil)
    }
}
