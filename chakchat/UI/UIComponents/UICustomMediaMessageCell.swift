//
//  UIPhotoMessageCell.swift
//  chakchat
//
//  Created by Кирилл Исаев on 17.04.2025.
//

import UIKit
import MessageKit
import AVFoundation

class CustomMediaMessageCell: MediaMessageCell {
    
    private let shimmerView: ShimmerView = ShimmerView(frame: CGRect(x: 50, y: 50, width: 200, height: 200))
    weak var cellDelegate: FileMessageEditMenuDelegate?
    private var messageStatus: UILabel = UILabel()
    
    override func setupConstraints() {
        super.setupConstraints()
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        configureMessageStatus()
        messageContainerView.addSubview(shimmerView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async {
            self.shimmerView.frame = self.messageContainerView.bounds
            self.shimmerView.startAnimating()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    override func configure(
        with message: MessageType,
        at indexPath: IndexPath,
        and messagesCollectionView: MessagesCollectionView)
    {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        addLongPressMenu()
        
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
        
        switch message.kind {
        case .photo(let mediaItem), .video(let mediaItem):
            if let image = mediaItem.image {
                imageView.image = image
                shimmerView.isHidden = true
            } else {
                if let url = mediaItem.url {
                    DispatchQueue.global(qos: .userInteractive).async {
                        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                            guard let self = self else { return }
                            guard let data = data, error == nil, let image = UIImage(data: data) else {
                                return
                            }
                            ImageCacheManager.shared.saveImage(image, for: url as NSURL)
                            DispatchQueue.main.async {
                                self.imageView.image = image
                                self.shimmerView.isHidden = true
                            }
                        }.resume()
                    }
                }
            }
        default:
            break
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
    
    private func addLongPressMenu() {
        let interaction = UIContextMenuInteraction(delegate: self)
        messageContainerView.addInteraction(interaction)
        messageContainerView.isUserInteractionEnabled = true
    }
    
    private func startSendingAnimation(in cell: CustomMediaMessageCell) {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = .infinity
        cell.messageStatus.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    private func generateThumbnail(for videoURL: URL) -> UIImage {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let maxSize = CGSize(width: 380, height: 380)
        generator.maximumSize = maxSize
        
        do {
            let cgImage = try generator.copyCGImage(at: CMTime(value: 1, timescale: 60), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            let scaledImage = thumbnail.scaledToFit(maxSize: maxSize)
            return scaledImage
            
        } catch {
            return UIImage(systemName: "play.circle.fill") ?? UIImage()
        }
    }
}

class CustomMediaMessageSizeCalculator: MediaMessageSizeCalculator {
    
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

extension CustomMediaMessageCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let collectionView = self.superview as? UICollectionView,
              let indexPath = collectionView.indexPath(for: self) else {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            
            let reactions = UIAction(title: "Add Reaction", image: UIImage(systemName: "face.smiling")) { _ in
                self.showReactionsMenu(for: indexPath)
            }
            
            let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
                self.cellDelegate?.didTapCopy(for: indexPath)
            }
            
            let reply = UIAction(title: "Reply to", image: UIImage(systemName: "pencil.and.scribble")) { _ in
                self.cellDelegate?.didTapReply(for: indexPath)
            }
            
            let load = UIAction(title: "Load", image: UIImage(systemName: "square.and.arrow.down")) { _ in
                self.cellDelegate?.didTapLoad(for: indexPath)
            }
            
            let forward = UIAction(title: "Forward", image: UIImage(systemName: "arrow.up.message")) { _ in
                self.cellDelegate?.didTapForwardFile(for: indexPath)
            }
            
            let deleteForMe = UIAction(title: "Delete for me", image: UIImage(systemName: "person")) { _ in
                self.cellDelegate?.didTapDelete(for: indexPath, mode: .DeleteModeForSender)
            }
            
            let deleteForEveryone = UIAction(title: "Delete for all", image: UIImage(systemName: "person.3.fill")) { _ in
                self.cellDelegate?.didTapDelete(for: indexPath, mode: .DeleteModeForAll)
            }
            
            let deleteMenu = UIMenu(title: "Delete", image: UIImage(systemName: "trash"), options: .destructive, children: [deleteForMe, deleteForEveryone])
            
            return UIMenu(title: "", children: [copy, reply, load, forward, deleteMenu])
        }
    }
    
    private func showReactionsMenu(for indexPath: IndexPath) {
        let reactionsVC = ReactionsPreviewViewController()
        reactionsVC.preferredContentSize = CGSize(width: 280, height: 50)
        reactionsVC.modalPresentationStyle = .popover
        reactionsVC.reactionSelected = { [weak self] emoji in
            self?.cellDelegate?.didSelectReaction(nil, emoji, for: indexPath) // мы только добавляем реакцию, значит у нее пока нет updateID(nil)
        }
        if let popover = reactionsVC.popoverPresentationController {
            popover.sourceView = self
            popover.sourceRect = self.bounds
            popover.permittedArrowDirections = []
            popover.delegate = self
        }
        self.window?.rootViewController?.present(reactionsVC, animated: true)
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        params.shadowPath = UIBezierPath(rect: .zero)
        params.visiblePath = UIBezierPath(rect: self.messageContainerView.bounds)
        return UITargetedPreview(view: self.messageContainerView, parameters: params)
    }
}

extension CustomMediaMessageCell: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
