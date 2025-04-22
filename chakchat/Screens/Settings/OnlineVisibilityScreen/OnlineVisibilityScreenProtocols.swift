//
//  OnlineVisibilityScreenProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 31.01.2025.
//

import Foundation

// MARK: - OnlineVisibilityScreen Protocols
protocol OnlineVisibilityScreenBusinessLogic {
    func backToConfidentialityScreen(_ onlineRestriction: String)
    
    func loadUserRestrictions()
    func showUserRestrictions(_ onlineRestriction: OnlineVisibilityStatus)
    func saveNewRestrictions(_ onlineRestriction: OnlineVisibilityStatus)
    func showAddUsersScreen()
}

protocol OnlineVisibilityScreenPresentationLogic {
    func showUserRestrictions(_ onlineRestriction: OnlineVisibilityStatus)
}

protocol OnlineVisibilityScreenWorkerLogic {
    func saveNewRestrictions(_ newOnlineRestriction: OnlineVisibilityStatus)
}
