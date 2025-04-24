//
//  NewUpdateEvent.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.04.2025.
//

import Foundation

final class WSUpdateEvent: Event {
    
    let updateData: UpdateData
    
    init(updateData: UpdateData) {
        self.updateData = updateData
    }
}
