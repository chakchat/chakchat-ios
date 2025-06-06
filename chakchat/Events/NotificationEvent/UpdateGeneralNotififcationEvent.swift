//
//  UpdateGeneralNotififcationEvent.swift
//  chakchat
//
//  Created by Кирилл Исаев on 01.02.2025.
//

import Foundation

// MARK: - UpdateGeneralNotififcationEvent
final class UpdateGeneralNotififcationEvent: Event {
    
    var newGeneralNotififcationStatus: Bool
    
    init(newGeneralNotififcationStatus: Bool) {
        self.newGeneralNotififcationStatus = newGeneralNotififcationStatus
    }
}
