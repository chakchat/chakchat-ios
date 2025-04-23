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
        fileURL = nil
    }
    
    override func layoutMessageContainerView(with attributes: MessagesCollectionViewLayoutAttributes) {
        super.layoutMessageContainerView(with: attributes)
    }
    
    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        messageContainerView.isUserInteractionEnabled = true
        addGesture()
        
        guard case .text(let stringUrl) = message.kind else { return }
        guard let url = URL(string: stringUrl) else { return }
        
        if let cachedURL = FileCacheManager.shared.getFile(url) {
            messageLabel.text = cachedURL.lastPathComponent
        }
        
        messageLabel.pinCenterY(messageContainerView.centerYAnchor)
        messageLabel.pinLeft(fileImageView.trailingAnchor, 5)
        messageLabel.pinRight(messagesCollectionView.trailingAnchor, 5)
        messageLabel.setWidth(200)
        messageLabel.numberOfLines = 1
        messageLabel.lineBreakMode = .byTruncatingMiddle
    }
    
    private func configureCell() {
        configureFileImageView()
    }
    
    private func configureFileImageView() {
        messageContainerView.addSubview(fileImageView)
        fileImageView.contentMode = .scaleAspectFit
        fileImageView.image = UIImage(systemName: "document.circle.fill")
        fileImageView.tintColor = .orange
        fileImageView.isUserInteractionEnabled = true
        fileImageView.setWidth(50)
        fileImageView.setHeight(50)
        fileImageView.pinLeft(messageContainerView.leadingAnchor, 5)
        fileImageView.pinCenterY(messageContainerView)
    }
    
    private func addGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleFileIconTap))
        fileImageView.addGestureRecognizer(tapGesture)
    }
    
    private func open(_ url: URL) {
        DispatchQueue.main.async {
            let documentController = UIDocumentInteractionController(url: url)
            documentController.delegate = self
            documentController.presentPreview(animated: true)
        }
    }
    
    private func updateFileIcon(for fileExtension: String) {
        let ext = fileExtension.lowercased()
        switch ext {
        case "application/pdf":
            fileImageView.image = UIImage(systemName: "doc.richtext.fill")
        case "jpg", "jpeg", "png", "gif":
            fileImageView.image = UIImage(systemName: "photo.fill")
        case "txt", "rtf":
            fileImageView.image = UIImage(systemName: "doc.text.fill")
        case "doc", "docx":
            fileImageView.image = UIImage(systemName: "doc.fill")
        case "xls", "xlsx":
            fileImageView.image = UIImage(systemName: "chart.bar.doc.horizontal.fill")
        case "ppt", "pptx":
            fileImageView.image = UIImage(systemName: "rectangle.fill.on.rectangle.fill")
        default:
            fileImageView.image = UIImage(systemName: "document.circle.fill")
        }
    }
    
    @objc private func handleFileIconTap() {
        guard let fileURL = fileURL else { return }
        if let cachedURL = FileCacheManager.shared.getFile(fileURL) {
            open(cachedURL)
        }
    }
}

class FileMessageCellSizeCalculator: TextMessageSizeCalculator {
    
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
        var size = super.messageContainerSize(for: message, at: indexPath)
        size.height -= 20
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
