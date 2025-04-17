//
//  UIViewController+Alert.swift
//  chakchat
//
//  Created by лизо4ка курунок on 22.01.2025.
//

import Foundation
import UIKit

// MARK: - UIViewController Extension
extension UIViewController {
    
    // MARK: - Constants
    private static let sendEmailPrompt: String = "Try later or send us an email with the error details."
    
    // MARK: - Show Alert Method
    func showAlert(title: String = LocalizationManager.shared.localizedString(for: "error"), message: String?, cancelTitle: String = LocalizationManager.shared.localizedString(for: "cancel")) {
        let alert = UIAlertController(title: title, message: (message ?? LocalizationManager.shared.localizedString(for: "error")) + " " + UIViewController.sendEmailPrompt, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        let sendEmailAction = UIAlertAction(title: LocalizationManager.shared.localizedString(for: "send_email"), style: .default) { _ in
            MailHelper.shared.sendAutoErrorEmail(message: message, from: self)
        }
        alert.addAction(sendEmailAction)
        present(alert, animated: true, completion: nil)
    }
}
