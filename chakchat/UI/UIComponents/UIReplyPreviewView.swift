//
//  UIReplyPreviewView.swift
//  chakchat
//
//  Created by Кирилл Исаев on 13.04.2025.
//

import UIKit
import MessageKit

final class ReplyPreviewView: UIView {
    
    private let message: MessageType
    private var replyType: ReplyType
    private let senderLabel: UILabel = UILabel()
    private let messageLabel: UILabel = UILabel()
    private let contentView: UIView = UIView()
    private let previewImageView: UIImageView = UIImageView()
    private let closeButton: UIButton = UIButton(type: .system)
    
    var onClose: (() -> Void)?
    
    init(message: MessageType, type: ReplyType) {
        self.message = message
        self.replyType = type
        super.init(frame: .zero)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 8
        configureContentView()
        configureCloseButton()
        configureSenderLabel()
        configureMessageLabelOrImage()
    }
    
    private func configureContentView() {
        addSubview(contentView)
        contentView.setHeight(40)
        contentView.setWidth(self.bounds.width)
        contentView.pinTop(self.topAnchor, 8)
        contentView.pinBottom(self.bottomAnchor, 8)
        contentView.pinLeft(self.leadingAnchor, 12)
        contentView.pinRight(self.trailingAnchor, 12)
    }
    
    private func configureCloseButton() {
        contentView.addSubview(closeButton)
        closeButton.pinCenterY(contentView)
        closeButton.pinRight(contentView.safeAreaLayoutGuide.trailingAnchor, 0)
        closeButton.setHeight(20)
        closeButton.setWidth(20)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    private func configureSenderLabel() {
        contentView.addSubview(senderLabel)
        senderLabel.text = replyType == .reply ? "Replying to \(message.sender.displayName)" : "Editing"
        senderLabel.font = Fonts.systemR12
        senderLabel.pinLeft(contentView.safeAreaLayoutGuide.leadingAnchor, 0)
        senderLabel.pinTop(contentView.topAnchor, 0)
        senderLabel.setHeight(16)
        senderLabel.setWidth(250)
    }
    
    /// потом здесь надо будет обрабатывать все виды сообщений(пока только текстовое)
    private func configureMessageLabelOrImage() {
        switch message.kind {
        case .text(let text):
            contentView.addSubview(messageLabel)
            messageLabel.text = text
            messageLabel.font = Fonts.systemR12
            messageLabel.pinLeft(contentView.safeAreaLayoutGuide.leadingAnchor, 0)
            messageLabel.pinTop(senderLabel.bottomAnchor, 4)
            messageLabel.setHeight(16)
            messageLabel.setWidth(250)
            previewImageView.isHidden = true
        case .photo(let mediaItem), .video(let mediaItem):
            contentView.addSubview(previewImageView)
            previewImageView.clipsToBounds = true
            previewImageView.layer.cornerRadius = 4
            previewImageView.pinLeft(contentView.safeAreaLayoutGuide.leadingAnchor, 0)
            previewImageView.pinTop(senderLabel.bottomAnchor, 4)
            previewImageView.setWidth(30)
            previewImageView.setHeight(30)
            previewImageView.image = mediaItem.image
            messageLabel.isHidden = true
        default: break
        }
    }
    
    @objc private func closeTapped() {
        onClose?()
    }
}

enum ReplyType {
    case reply
    case edit
}
