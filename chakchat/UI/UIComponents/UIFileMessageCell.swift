//
//  UIFileMessageCell.swift
//  chakchat
//
//  Created by Кирилл Исаев on 18.04.2025.
//

import UIKit
import MessageKit

class FileMessageCell: TextMessageCell {
    
    weak var cellDelegate: FileMessageEditMenuDelegate?
    
    private var messageStatus: UILabel = UILabel()
    private var fileImageView: UIImageView = UIImageView()
    private var fileURL: URL?
    
    override func setupSubviews() {
        super.setupSubviews()
        configureCell()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    override func layoutMessageContainerView(with attributes: MessagesCollectionViewLayoutAttributes) {
        super.layoutMessageContainerView(with: attributes)
    }
    
    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        addGesture()
        
        guard case .text(let stringUrl) = message.kind else { return }
        
        self.fileURL = URL(string: stringUrl)
        messageLabel.text = fileURL?.lastPathComponent
        
        let fileExtension = fileURL?.pathExtension.lowercased()
        switch fileExtension {
        case "pdf":
            fileImageView.image = UIImage(systemName: "doc.richtext.fill")
        case "jpg", "jpeg", "png", "gif":
            fileImageView.image = UIImage(systemName: "photo.fill")
        case "txt", "rtf":
            fileImageView.image = UIImage(systemName: "doc.text.fill")
        default:
            fileImageView.image = UIImage(systemName: "document.circle.fill")
        }
        
        messageLabel.pinLeft(fileImageView.trailingAnchor, 5)
    }
    
    private func configureCell() {
        configureFileImageView()
    }
    
    private func configureFileImageView() {
        messageContainerView.addSubview(fileImageView)
        fileImageView.contentMode = .scaleAspectFit
        fileImageView.image = UIImage(systemName: "document.circle.fill")
        fileImageView.tintColor = .blue
        fileImageView.isUserInteractionEnabled = true
        fileImageView.setWidth(30)
        fileImageView.setHeight(30)
        fileImageView.pinLeft(messageContainerView.leadingAnchor, 5)
        fileImageView.pinCenterY(messageContainerView)
    }
    
    private func addGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleFileIconTap))
        fileImageView.addGestureRecognizer(tapGesture)
    }
    
    private func open(_ url: URL) {
        let documentController = UIDocumentInteractionController(url: url)
        documentController.delegate = self
        documentController.presentPreview(animated: true)
    }
    
    @objc private func handleFileIconTap() {
        guard let fileURL = fileURL else { return }
        open(fileURL)
    }
}

class FileMessageCellSizeCalculator: TextMessageSizeCalculator {
    
    override func messageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        let size = super.messageContainerSize(for: message, at: indexPath)
        return size
    }
    
}

extension FileMessageCell: UIDocumentInteractionControllerDelegate {
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        guard let root = getRootViewController() else {
            print("Unlucky")
            return UIViewController()
        }
        return root
    }
    
    func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("Unlucky")
            return nil
        }
        return rootViewController
    }
}
