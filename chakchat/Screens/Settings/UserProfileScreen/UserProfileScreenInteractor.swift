//
//  UserProfileScreenInteractor.swift
//  chakchat
//
//  Created by Кирилл Исаев on 06.02.2025.
//

import UIKit
import OSLog
import Combine

// MARK: - UserProfileScreenInteractor
final class UserProfileScreenInteractor: UserProfileScreenBusinessLogic {
    
    // MARK: - Properties
    private let presenter: UserProfileScreenPresentationLogic
    private let worker: UserProfileScreenWorkerLogic
    private let eventSubscriber: EventSubscriberProtocol
    private let errorHandler: ErrorHandlerLogic
    private let logger: OSLog
    
    private var cancellables = Set<AnyCancellable>()
    
    var onRouteToSettingsScreen: (() -> Void)?
    var onRouteToProfileSettingsScreen: (() -> Void)?
    var onRouteToRegistration: (() -> Void)?
    
    // MARK: Initialization
    init(preseter: UserProfileScreenPresentationLogic,
         worker: UserProfileScreenWorkerLogic,
         eventSubscriber: EventSubscriberProtocol,
         errorHandler: ErrorHandlerLogic,
         logger: OSLog
    ) {
        self.presenter = preseter
        self.worker = worker
        self.eventSubscriber = eventSubscriber
        self.errorHandler = errorHandler
        self.logger = logger
        
        subscribeToEvents()
    }
    
    // MARK: - Public Methods
    // on this screen we are downloading data only from UserDefaults, because we have you already sent a get request to the server
    func loadUserData() {
        os_log("Loaded user data in user profile scree", log: logger, type: .default)
        let userData = worker.getUserData()
        showUserData(userData)
    }
    
    func showUserData(_ userData: ProfileSettingsModels.ProfileUserData) {
        os_log("Passed user data in user settings screen to presenter", log: logger, type: .default)
        presenter.showUserData(userData)
    }
    
    func showNewUserData(_ userData: ProfileSettingsModels.ChangeableProfileUserData) {
        os_log("Passed new user data in user settings screen to presenter", log: logger, type: .default)
        presenter.showNewUserData(userData)
    }
    
    func showNewPhoto(_ photo: URL?) {
        os_log("Passed new photo in user settings screen to presenter", log: logger, type: .default)
        presenter.showNewPhoto(photo)
    }
    
    func handlePhotoChangedEvent(_ event: UpdatePhotoEvent) {
        os_log("Handled photo changes in user profile screen", log: logger, type: .default)
        let newPhoto = event.newPhoto
        DispatchQueue.main.async {
            self.showNewPhoto(newPhoto)
        }
    }
    
    func handleUserDataChangedEvent(_ event: UpdateProfileDataEvent) {
        os_log("Handled user data changes in user profile screen", log: logger, type: .default)
        let newUserData = ProfileSettingsModels.ChangeableProfileUserData(name: event.newNickname,
                                                                          username: event.newUsername,
                                                                          dateOfBirth: event.newBirth)
        showNewUserData(newUserData)
    }
    
    func backToSettingsMenu() {
        os_log("Routed to setting screen from user profile screen", log: logger, type: .default)
        onRouteToSettingsScreen?()
    }
    
    func profileSettingsRoute() {
        os_log("Routed to profile setting screen from user profile screen", log: logger, type: .default)
        onRouteToProfileSettingsScreen?()
    }
    
    func signOut() {
        worker.signOut { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(_):
                os_log("Signout from account, data deleted", log: logger, type: .info)
                backToRegistration()
            case .failure(let failure):
                _ = self.errorHandler.handleError(failure)
                os_log("Failed to signout:\n", log: logger, type: .fault)
                print(failure)
            }
        }
    }
    
    private func subscribeToEvents() {
        eventSubscriber.subscribe(UpdateProfileDataEvent.self) { [weak self] event in
            self?.handleUserDataChangedEvent(event)
        }.store(in: &cancellables)
        eventSubscriber.subscribe(UpdatePhotoEvent.self) { [weak self] event in
            self?.handlePhotoChangedEvent(event)
        }.store(in: &cancellables)
    }
    
    func backToRegistration() {
        os_log("Routed to registration", log: logger, type: .default)
        DispatchQueue.main.async {
            self.onRouteToRegistration?()
        }
    }
}
