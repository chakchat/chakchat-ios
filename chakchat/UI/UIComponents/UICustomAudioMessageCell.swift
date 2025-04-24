//
//  UICustomAudioMessageCell.swift
//  chakchat
//
//  Created by Кирилл Исаев on 20.04.2025.
//

import UIKit
import MessageKit
import AVFAudio

class CustomAudioMessageCell: AudioMessageCell {
    
    weak var cellDelegate: FileMessageEditMenuDelegate?
    private var messageStatus: UILabel = UILabel()
    
    override func setupConstraints() {
        super.setupConstraints()
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        configureCell()
    }
    
    override func prepareForReuse() {
      super.prepareForReuse()
    }
    
    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        addLongPressMenu()
        updateStatus(message)
        guard case .audio(let audioData) = message.kind else { return }
        guard let audioData = audioData as? AudioMediaItem else { return }
        //FileCacheManager.shared.saveFile(audioData.url) { _ in }
    }
    
    private func configureCell() {
        configureMessageStatus()
    }
    
    private func configureMessageStatus() {
        messageContainerView.addSubview(messageStatus)
        messageStatus.font = UIFont.systemFont(ofSize: 10)
        messageStatus.textColor = .white
        messageStatus.setWidth(10)
        messageStatus.setHeight(10)
        messageStatus.pinRight(messageContainerView.trailingAnchor, 5)
        messageStatus.pinBottom(messageContainerView.bottomAnchor, 5)
    }
    
    private func updateStatus(_ message: MessageType) {
        if let message = message as? GroupMessageStatusProtocol {
            messageStatus.text = message.status.rawValue
            if message.status == .sending {
                startSendingAnimation(in: self)
            } else {
                if message.status == .read {
                    messageStatus.textColor = .chakChat
                } else if message.status == .error {
                    messageStatus.text = MessageStatus.error.rawValue
                }
                messageStatus.layer.removeAllAnimations()
            }
        }
    }
    
    private func startSendingAnimation(in cell: CustomAudioMessageCell) {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = .infinity
        cell.messageStatus.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    private func addLongPressMenu() {
        let interaction = UIContextMenuInteraction(delegate: self)
        messageContainerView.addInteraction(interaction)
        messageContainerView.isUserInteractionEnabled = true
    }
    
    private func getDuration(from url: URL, completion: @escaping (Float) -> Void) {
        DispatchQueue.global().async {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                let duration = Float(player.duration)
                DispatchQueue.main.async {
                    completion(duration)
                }
            } catch {
                print("Failed to get audio duration \(error)")
                DispatchQueue.main.async {
                    completion(0)
                }
            }
        }
    }
}

extension CustomAudioMessageCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
}
