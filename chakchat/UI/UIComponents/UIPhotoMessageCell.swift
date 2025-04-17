//
//  UIPhotoMessageCell.swift
//  chakchat
//
//  Created by Кирилл Исаев on 17.04.2025.
//

import UIKit
import MessageKit

class PhotoMessageCell: MediaMessageCell {
    
    private var shimmerView: ShimmerView?
    private var messageStatus: UILabel = UILabel()
    
    override func setupConstraints() {
        super.setupConstraints()
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
    }
    
    override func prepareForReuse() {
      super.prepareForReuse()
        shimmerView?.removeFromSuperview()
        shimmerView = nil
        configureMessageStatus()
    }
    
    override func configure(
        with message: MessageType,
        at indexPath: IndexPath,
        and messagesCollectionView: MessagesCollectionView)
    {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        shimmerView?.removeFromSuperview()
        shimmerView = nil
        
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
        
        guard case .photo(let photoMediaItem) = message.kind else { return }
        
        if let image = photoMediaItem.image {
            imageView.image = image
        } else {
            let shimmer = ShimmerView(frame: imageView.bounds)
            shimmer.startAnimating()
            shimmer.layer.cornerRadius = 0
            imageView.addSubview(shimmer)
            shimmerView = shimmer
            
            if let url = photoMediaItem.url {
                DispatchQueue.global(qos: .userInteractive).async {
                    URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                        guard let self = self else { return }
                        guard let data = data, error == nil, let image = UIImage(data: data) else {
                            return
                        }
                        ImageCacheManager.shared.saveImage(image, for: url as NSURL)
                        DispatchQueue.main.async {
                            self.imageView.image = image
                            self.shimmerView?.removeFromSuperview()
                            self.shimmerView = nil
                        }
                    }
                }
            }
        }
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
    
    private func startSendingAnimation(in cell: PhotoMessageCell) {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = .infinity
        cell.messageStatus.layer.add(rotation, forKey: "rotationAnimation")
    }
}

class PhotoMessageCellSizeCalculator: MediaMessageSizeCalculator {
    
    override func messageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        let size = super.messageContainerSize(for: message, at: indexPath)
        return size
    }
}
