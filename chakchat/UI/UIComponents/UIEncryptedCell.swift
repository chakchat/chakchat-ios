//
//  UIEncryptedCell.swift
//  chakchat
//
//  Created by Кирилл Исаев on 23.04.2025.
//

import UIKit
import MessageKit

final class EncryptedCell: TextMessageCell {
    
    override func setupSubviews() {
        super.setupSubviews()
        messageLabel.text = "ENCRYPTED"
        messageLabel.font = Fonts.specialGothic
        messageLabel.textColor = .red
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
    }
}

final class EncryptedCellSizeCalculator: TextMessageSizeCalculator {
    
    private let isGroupChat: Bool

    init(layout: MessagesCollectionViewFlowLayout, isGroupChat: Bool) {
        self.isGroupChat = isGroupChat
        super.init(layout: layout)

        if isGroupChat {
            incomingAvatarSize = CGSize(width: 30, height: 30)
            outgoingAvatarSize = .zero
        } else {
            incomingAvatarSize = .zero
            outgoingAvatarSize = .zero
        }
    }
    
    override func messageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        let size = super.messageContainerSize(for: message, at: indexPath)
        return size
    }
}
