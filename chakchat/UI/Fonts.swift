//
//  Fonts.swift
//  chakchat
//
//  Created by лизо4ка курунок on 31.01.2025.
//

import UIKit

// MARK: - Fonts
enum Fonts {
    // Used: Enter text in button on SendCodeVC
    static let systemB30: UIFont = UIFont.systemFont(ofSize: 30, weight: .bold)
    // Used: Resend text in button on VerifyVC
    static let systemB25: UIFont = UIFont.systemFont(ofSize: 25, weight: .bold)
    // Used: Name and username text in SignupVC
    static let interR20: UIFont = UIFont.loadCustomFont(name: "Inter-Regular", size: 20)
    // Used: Create account text in button on SignupVC
    static let systemB20: UIFont = UIFont.systemFont(ofSize: 20, weight: .bold)
    // Used: Big ChakChat label in StartVC
    static let rammettoOneR100: UIFont = UIFont.loadCustomFont(name: "RammettoOne-Regular", size: 100)
    // Used: Tap label text in StartVC
    static let montserratB25: UIFont = UIFont.loadCustomFont(name: "Montserrat-Bold", size: 25)
    static let specialGothic: UIFont = UIFont.loadCustomFont(name: "SpecialGothicExpandedOne-Regular", size: 18)
    // Used: ChatsVc, SettingsVC, NotificationsVC ...... as a header
    static let systemB24: UIFont = UIFont.systemFont(ofSize: 24, weight: .bold)
    // Used: ProfileSettingsVC as a header
    static let systemB18: UIFont = UIFont.systemFont(ofSize: 18, weight: .bold)
    // Used: SettingsVC - nicknameLabel
    static let systemSB20: UIFont =  UIFont.systemFont(ofSize: 20, weight: .semibold)
    static let systemSB18: UIFont =  UIFont.systemFont(ofSize: 18, weight: .semibold)
    // Used: SettingsVC - phone and username
    static let systemL14: UIFont = UIFont.systemFont(ofSize: 14, weight: .light)
    // Used: SettingsVC - dot between phone and username
    static let systemB16: UIFont = UIFont.systemFont(ofSize: 16, weight: .bold)
    // Used: SettingsVC - cell label
    static let systemR16: UIFont = UIFont.systemFont(ofSize: 16, weight: .regular)
    // Used: SettingsVC - text in textFields
    static let systemM17: UIFont = UIFont.systemFont(ofSize: 17, weight: .regular)
    // Used: UserProfileVC
    static let systemR18: UIFont = UIFont.systemFont(ofSize: 18, weight: .regular)
    // Used: LanguageVC
    static let systemR12: UIFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    // Used: SendCodeVC
    static let systemR15: UIFont = UIFont.systemFont(ofSize: 15, weight: .regular)
    static let systemR20: UIFont = UIFont.systemFont(ofSize: 20, weight: .regular)
}
