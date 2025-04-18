//
//  UIPhotoMessageCell.swift
//  chakchat
//
//  Created by Кирилл Исаев on 17.04.2025.
//

import UIKit
import MessageKit

class CustomMediaMessageCell: MediaMessageCell {
    
    weak var cellDelegate: FileMessageEditMenuDelegate?
    private var messageStatus: UILabel = UILabel()
    
    override func setupConstraints() {
        super.setupConstraints()
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        configureMessageStatus()
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
}

class PhotoMessageCellSizeCalculator: MediaMessageSizeCalculator {
    
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
            
            let deleteForMe = UIAction(title: "Delete for me", image: UIImage(systemName: "person")) { _ in
                self.cellDelegate?.didTapDelete(for: indexPath, mode: .DeleteModeForSender)
            }
            
            let deleteForEveryone = UIAction(title: "Delete for all", image: UIImage(systemName: "person.3.fill")) { _ in
                self.cellDelegate?.didTapDelete(for: indexPath, mode: .DeleteModeForAll)
            }
            
            let deleteMenu = UIMenu(title: "Delete", image: UIImage(systemName: "trash"), options: .destructive, children: [deleteForMe, deleteForEveryone])
            
            return UIMenu(title: "", children: [copy, reactions, reply, load, deleteMenu])
        }
    }
    
    private func showReactionsMenu(for indexPath: IndexPath) {
        let reactionsVC = ReactionsPreviewViewController()
        reactionsVC.preferredContentSize = CGSize(width: 240, height: 50)
        reactionsVC.modalPresentationStyle = .popover
        reactionsVC.reactionSelected = { [weak self] emoji in
            self?.cellDelegate?.didSelectReaction(emoji, true, for: indexPath)
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
