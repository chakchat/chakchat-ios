//
//  UIHiddenMessageCellSizeCalculator.swift
//  chakchat
//
//  Created by Кирилл Исаев on 12.04.2025.
//

import Foundation
import MessageKit

final class HiddenMessageSizeCalculator: MessageSizeCalculator {
     func messageContainerSize(for message: MessageType) -> CGSize {
        return .zero
    }
}
