//
//  AppCoordinator.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.01.2025.
//

import Foundation
import UIKit
import OSLog

// MARK: - AppCoordinator
final class AppCoordinator {
    
    // MARK: - Properties
    private let window: UIWindow
    private let navigationController: UINavigationController
    private var mainChatVC: UIViewController?
    private let signupContext: SignupContextProtocol
    private let mainAppContext: MainAppContextProtocol

    // MARK: - Initialization
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
        let keychainManager = KeychainManager()
        let identityService = IdentityService()
        let userDefaultsManager = UserDefaultsManager()
        let errorHandler = ErrorHandler(keychainManager: keychainManager, identityService: identityService)
        self.signupContext = SignupContext(keychainManager: keychainManager,
                                           errorHandler: errorHandler,
                                           userDefaultsManager: userDefaultsManager,
                                           state: SignupState._default,
                                           logger: OSLog(subsystem: "com.chakchat.mainlog", category: "MainLog"))
        
        self.mainAppContext = MainAppContext(keychainManager: signupContext.keychainManager,
                                             errorHandler: signupContext.errorHandler,
                                             userDefaultsManager: signupContext.userDefaultsManager,
                                             eventManager: EventManager(),
                                             coreDataManager: CoreDataManager(),
                                             state: AppState._default,
                                             logger: signupContext.logger)
    }

    // MARK: - Public Methods
    func start() {
//        if signupContext.keychainManager.getString(key: KeychainManager.keyForSaveAccessToken) != nil {
//            let chatVC = ChatsAssembly.build(with: mainAppContext, coordinator: self)
//            navigationController.pushViewController(chatVC, animated: false)
//        } else {
//            let startVC = CreateStartScreen()
//            navigationController.pushViewController(startVC, animated: false)
//        }
        let startVC = CreateStartScreen()
        navigationController.pushViewController(startVC, animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    private func CreateStartScreen() -> UIViewController {
        return StartAssembly.build(with: signupContext, coordinator: self)
    }
    
    func showRegistrationScreen() {
        let registrationVC = SendCodeAssembly.build(with: signupContext, coordinator: self)
        navigationController.setViewControllers([registrationVC], animated: true)
    }

    func showVerifyScreen() {
        let verifyVC = VerifyAssembly.build(with: signupContext, coordinator: self)
        navigationController.pushViewController(verifyVC, animated: true)
    }
    
    func showSignupScreen() {
        let signupVC = SignupAssembly.build(with: signupContext, coordinator: self)
        navigationController.pushViewController(signupVC, animated: true)
    }
    
    func setChatsScreen() {
        let mainVC = CreateChatsScreen()
        mainChatVC = mainVC
        navigationController.setViewControllers([mainVC], animated: true)
    }
    
    func popScreen() {
        navigationController.popViewController(animated: true)
    }

    private func CreateChatsScreen() -> UIViewController {
        return ChatsAssembly.build(with: mainAppContext, coordinator: self)
    }
    
    func showSettingsScreen() {
        let settingsVC = SettingsScreenAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(settingsVC, animated: true)
    }
    
    func showUserSettingsScreen() {
        let userSettingsVC = UserProfileScreenAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(userSettingsVC, animated: true)
    }
    
    func showProfileSettingsScreen() {
        let profileSettingsVC = ProfileSettingsAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(profileSettingsVC, animated: true)
    }
    
    func showConfidentialityScreen() {
        let confVC = ConfidentialityScreenAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(confVC, animated: true)
    }
    
    func showPhoneVisibilityScreen() {
        let phoneVisibilityVC = PhoneVisibilityScreenAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(phoneVisibilityVC, animated: true)
    }

    func showBirthVisibilityScreen() {
        let birthVisibilityVC = BirthVisibilityScreenAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(birthVisibilityVC, animated: true)
    }
    
    func showOnlineVisibilityScreen() {
        let onlineVisibilityVC = OnlineVisibilityScreenAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(onlineVisibilityVC, animated: true)
    }
    
    func showNotificationScreen() {
        let notificationVC = NotificationScreenAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(notificationVC, animated: true)
    }
    
    func showLanguageScreen() {
        let languageVC = LanguageAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(languageVC, animated: true)
    }

    func showAppThemeScreen() {
        let appThemeVC = AppThemeAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(appThemeVC, animated: true)
    }
    
    func showCacheScreen() {
        let cacheVC = CacheAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(cacheVC, animated: true)
    }
    
    func showHelpScreen() {
        let helpVC = HelpAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(helpVC, animated: true)
    }
    
    func showBlackListScreen() {
        let blackListVC = BlackListAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(blackListVC, animated: true)
    }
    
    func showNewMessageScreen() {
        let newMessageVC = NewMessageAssembly.build(with: mainAppContext, coordinator: self)
        if let mainVC = mainChatVC {
            navigationController.setViewControllers([mainVC, newMessageVC], animated: true)
        } else {
            let mainVC = CreateChatsScreen()
            navigationController.setViewControllers([mainVC, newMessageVC], animated: true)
        }
    }
    
    func showChatScreen(
        _ userData: ProfileSettingsModels.ProfileUserData,
        _ chatData: ChatsModels.GeneralChatModel.ChatData?
    ) {
        let chatVC = ChatAssembly.build(mainAppContext, coordinator: self, userData: userData, chatData: chatData)
        if let mainVC = mainChatVC {
            navigationController.setViewControllers([mainVC, chatVC], animated: true)
        } else {
            let mainVC = CreateChatsScreen()
            navigationController.setViewControllers([mainVC, chatVC], animated: true)
        }
    }
    
    func showUserProfileScreen(
        _ userData: ProfileSettingsModels.ProfileUserData,
        _ chatData: ChatsModels.GeneralChatModel.ChatData?,
        _ profileConfiguration: ProfileConfiguration
    ) {
        let userProfileVC = UserProfileAssembly.build(mainAppContext, coordinator: self, userData: userData,  chatData: chatData, profileConfiguration: profileConfiguration)
        navigationController.pushViewController(userProfileVC, animated: true)
    }

    func showNewGroupScreen() {
        let newGroupVC = NewGroupAssembly.build(with: mainAppContext, coordinator: self)
        navigationController.pushViewController(newGroupVC, animated: true)
    }
    
    func showGroupChatScreen(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        let groupChatVC = GroupChatAssembly.build(with: mainAppContext, coordinator: self, chatData)
        if let mainVC = mainChatVC {
            navigationController.setViewControllers([mainVC, groupChatVC], animated: true)
        } else {
            let mainVC = CreateChatsScreen()
            navigationController.setViewControllers([mainVC, groupChatVC], animated: true)
        }
    }
    
    func showGroupChatProfile(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        let groupChatProfileVC = GroupChatProfileAssembly.build(with: mainAppContext, coordinator: self, chatData)
        navigationController.pushViewController(groupChatProfileVC, animated: true)
    }
    
    func showGroupProfileEditScreen(_ chatData: GroupProfileEditModels.ProfileData) {
        let groupEditVC = GroupProfileEditAssembly.build(with: mainAppContext, coordinator: self, chatData)
        navigationController.pushViewController(groupEditVC, animated: true)
    }
}
