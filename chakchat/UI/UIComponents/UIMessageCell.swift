//
//  UIMessageCell.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.04.2025.
//

import UIKit

final class UIMessageCell: UICollectionViewCell {
    
    static let cellIdentifier: String = "MessageCell"
    
    
    private let messageLabel = UILabel()
    private let statusIcon = UIImageView()
    private let bubbleView = UIView()
    private var leadingConstraint = NSLayoutConstraint()
    private var trailingConstraint = NSLayoutConstraint()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.frame = CGRect(x: 177, y: 8, width: 200, height: 40)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ message: ChatModels.Message, _ curUserID: UUID) {
        let isMy = message.senderID == curUserID
        messageLabel.text = message.text
        
        bubbleView.backgroundColor = isMy ? .systemBlue : .secondarySystemBackground
        messageLabel.textColor = isMy ? .white : .label
        statusIcon.tintColor = .white
        statusIcon.isHidden = !isMy
        
        messageLabel.textAlignment = isMy ? .right : .left
        
        leadingConstraint.isActive = !isMy
        trailingConstraint.isActive = isMy
    }
    
    private func configureCell() {
        configureBubbleView()
        configureStatusIcon()
        configureMessageLabel()
        configureConstraints()
    }
    
    private func configureBubbleView() {
        contentView.addSubview(bubbleView)
        bubbleView.layer.cornerRadius = 16
        bubbleView.clipsToBounds = true
        bubbleView.pinTop(contentView.topAnchor, 4)
        bubbleView.pinBottom(contentView.bottomAnchor, 4)
    }
    
    private func configureStatusIcon() {
        contentView.addSubview(statusIcon)
        statusIcon.contentMode = .scaleAspectFit
        statusIcon.pinRight(bubbleView.trailingAnchor, 8)
        statusIcon.pinBottom(bubbleView.bottomAnchor, 6)
        statusIcon.setWidth(14)
        statusIcon.setHeight(14)
    }
    
    private func configureMessageLabel() {
        contentView.addSubview(messageLabel)
        messageLabel.numberOfLines = 0
        messageLabel.font = Fonts.systemR16
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.pinTop(bubbleView.topAnchor, 8)
        messageLabel.pinBottom(bubbleView.bottomAnchor, 8)
        messageLabel.pinLeft(bubbleView.leadingAnchor, 12)
        messageLabel.pinRight(statusIcon.trailingAnchor, 8)
    }
    
    private func configureConstraints() {
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 100)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -100)
        leadingConstraint.priority = .defaultHigh
        trailingConstraint.priority = .defaultHigh
        leadingConstraint.isActive = true
        trailingConstraint.isActive = false
    }
}
