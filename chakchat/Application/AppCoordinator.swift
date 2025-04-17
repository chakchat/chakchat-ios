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
    static let shared = AppCoordinator()
    private var window: UIWindow = UIWindow()

    private let navigationController: UINavigationController
    private var mainChatVC: UIViewController?
    private let signupContext: SignupContextProtocol
    private let mainAppContext: MainAppContextProtocol

    func setWindow(_ window: UIWindow) {
        self.window = window
    }
    
    private init() {
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
    func startRegistration() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        showSendCodeScreen()
    }
    
    func startChats() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        setChatsScreen()
    }
    
    func tryRefreshAccessToken(completion: @escaping (Bool) -> Void) {
        if isUserLoggedIn() {
            refreshAccessToken { success in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    
    private func isUserLoggedIn() -> Bool {
        let token = signupContext.keychainManager.getString(key: KeychainManager.keyForSaveAccessToken)
        return token != nil
    }
    
    private func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        let identityService = IdentityService()
        guard let refreshToken = mainAppContext.keychainManager.getString(key: KeychainManager.keyForSaveRefreshToken) else {
            completion(false)
            return
        }
        
        identityService.sendRefreshTokensRequest(RefreshRequest(refreshToken: refreshToken)) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion(false)
                    return
                }
                
                switch result {
                case .success(let keys):
                    _ = self.mainAppContext.keychainManager.save(key: KeychainManager.keyForSaveAccessToken, value: keys.data.accessToken)
                    _ = self.mainAppContext.keychainManager.save(key: KeychainManager.keyForSaveRefreshToken, value: keys.data.refreshToken)
                    completion(true)
                    
                case .failure(let failure):
                    if let error = failure as? APIErrorResponse,
                       error.errorType == ApiErrorType.refreshTokenExpired.rawValue {
                        self.signupContext.errorHandler.handleRefreshTokenError()
                    }
                    completion(false)
                }
            }
        }
    }
    
    func showSendCodeScreen()  {
        let sendCodeVC = SendCodeAssembly.build(with: signupContext)
        navigationController.pushViewController(sendCodeVC, animated: true)
    }

    func showVerifyScreen(_ phone: String) {
        let verifyVC = VerifyAssembly.build(with: signupContext, phone: phone)
        navigationController.pushViewController(verifyVC, animated: true)
    }
    
    func showSignupScreen() {
        let signupVC = SignupAssembly.build(with: signupContext)
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
        return ChatsAssembly.build(with: mainAppContext)
    }
    
    func showSettingsScreen() {
        let settingsVC = SettingsScreenAssembly.build(with: mainAppContext)
        navigationController.pushViewController(settingsVC, animated: true)
    }
    
    func showUserSettingsScreen() {
        let userSettingsVC = UserProfileScreenAssembly.build(with: mainAppContext)
        navigationController.pushViewController(userSettingsVC, animated: true)
    }
    
    func showProfileSettingsScreen() {
        let profileSettingsVC = ProfileSettingsAssembly.build(with: mainAppContext)
        navigationController.pushViewController(profileSettingsVC, animated: true)
    }
    
    func showConfidentialityScreen() {
        let confVC = ConfidentialityScreenAssembly.build(with: mainAppContext)
        navigationController.pushViewController(confVC, animated: true)
    }
    
    func showPhoneVisibilityScreen() {
        let phoneVisibilityVC = PhoneVisibilityScreenAssembly.build(with: mainAppContext)
        navigationController.pushViewController(phoneVisibilityVC, animated: true)
    }

    func showBirthVisibilityScreen() {
        let birthVisibilityVC = BirthVisibilityScreenAssembly.build(with: mainAppContext)
        navigationController.pushViewController(birthVisibilityVC, animated: true)
    }
    
    func showOnlineVisibilityScreen() {
        let onlineVisibilityVC = OnlineVisibilityScreenAssembly.build(with: mainAppContext)
        navigationController.pushViewController(onlineVisibilityVC, animated: true)
    }
    
    func showNotificationScreen() {
        let notificationVC = NotificationScreenAssembly.build(with: mainAppContext)
        navigationController.pushViewController(notificationVC, animated: true)
    }
    
    func showLanguageScreen() {
        let languageVC = LanguageAssembly.build(with: mainAppContext)
        navigationController.pushViewController(languageVC, animated: true)
    }

    func showAppThemeScreen() {
        let appThemeVC = AppThemeAssembly.build(with: mainAppContext)
        navigationController.pushViewController(appThemeVC, animated: true)
    }
    
    func showCacheScreen() {
        let cacheVC = CacheAssembly.build(with: mainAppContext)
        navigationController.pushViewController(cacheVC, animated: true)
    }
    
    func showHelpScreen() {
        let helpVC = HelpAssembly.build(with: mainAppContext)
        navigationController.pushViewController(helpVC, animated: true)
    }
    
    func showBlackListScreen() {
        let blackListVC = BlackListAssembly.build(with: mainAppContext)
        navigationController.pushViewController(blackListVC, animated: true)
    }
    
    func showNewMessageScreen() {
        let newMessageVC = NewMessageAssembly.build(with: mainAppContext)
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
        let chatVC = ChatAssembly.build(mainAppContext, userData: userData, chatData: chatData)
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
        let userProfileVC = UserProfileAssembly.build(mainAppContext, userData: userData,  chatData: chatData, profileConfiguration: profileConfiguration)
        navigationController.pushViewController(userProfileVC, animated: true)
    }

    func showNewGroupScreen() {
        let newGroupVC = NewGroupAssembly.build(with: mainAppContext)
        navigationController.pushViewController(newGroupVC, animated: true)
    }
    
    func showGroupChatScreen(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        let groupChatVC = GroupChatAssembly.build(with: mainAppContext, chatData)
        if let mainVC = mainChatVC {
            navigationController.setViewControllers([mainVC, groupChatVC], animated: true)
        } else {
            let mainVC = CreateChatsScreen()
            navigationController.setViewControllers([mainVC, groupChatVC], animated: true)
        }
    }
    
    func showGroupChatProfile(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        let groupChatProfileVC = GroupChatProfileAssembly.build(with: mainAppContext, chatData)
        navigationController.pushViewController(groupChatProfileVC, animated: true)
    }
    
    func showGroupProfileEditScreen(_ chatData: GroupProfileEditModels.ProfileData) {
        let groupEditVC = GroupProfileEditAssembly.build(with: mainAppContext, chatData)
        navigationController.pushViewController(groupEditVC, animated: true)
    }
    
    func showAddUsersScreen() {
        let addUsersVC = AddUserAssembly.build(with: mainAppContext)
        navigationController.pushViewController(addUsersVC, animated: true)
    }
}
