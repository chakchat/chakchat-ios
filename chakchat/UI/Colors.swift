//
//  Colors.swift
//  chakchat
//
//  Created by лизо4ка курунок on 22.01.2025.
//

import Foundation
import UIKit

// MARK: - Colors
enum Colors {
    // Used in Start Screen, as ErrorLabel color.
    static let orange: UIColor = UIColor(hex: "FF6200") ?? UIColor.orange
    // Used in Start Screen.
    static let yellow: UIColor = UIColor(hex: "FFBF00") ?? UIColor.yellow
    // Used in Verify Screen as links color.
    static let darkYellow: UIColor = UIColor(hex: "#FFAE00") ?? UIColor.systemYellow
    // Used as fields border color.
    static let gray: UIColor = UIColor(hex: "#383838") ?? UIColor.gray
    // Used in settings.
    static let lightOrange: UIColor = UIColor(hex: "FF9D00") ?? UIColor.orange
    // Used when alerts showing
    static let blackout: UIColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
    // Used as background
    static let background: UIColor = UIColor(named: "BackgroundColor") ?? .systemBackground
    // Used as background on the settings screen
    static let backgroundSettings: UIColor = UIColor(named: "BackgroundSettingsColor") ?? .systemBackground
    // Used for text
    static let text: UIColor = UIColor(named: "TextColor") ?? .label
    // Used for chakchat Label
    static let chakchat: UIColor = UIColor(named: "ChakChatColor") ?? .orange
    // Used for footer
    static let footer: UIColor = UIColor(named: "FooterColor") ?? .systemGray5
    // Used for alerts
    static let picker: UIColor = UIColor(named: "PickerColor") ?? .tertiaryLabel
    // Used for user buttons
    static let userButtons: UIColor = UIColor(named: "UserButtonColor") ?? .systemGray6
    // Used as messageViewBackground
    static let messageColor: UIColor = UIColor(named: "MessageColor") ?? .white
    // Used as messageInputBarBackground
    static let inputBar: UIColor = UIColor(named: "InputMessageBarColor") ?? .white
    
    static let disableButton: UIColor = UIColor(named: "DisabledSendButtonColor") ?? .white
    static let inputBarBorder: UIColor = UIColor(named: "InputBarBorderColor") ?? .white
}
