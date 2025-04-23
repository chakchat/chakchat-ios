//
//  UIFileMessageCell.swift
//  chakchat
//
//  Created by Кирилл Исаев on 18.04.2025.
//

import UIKit
import MessageKit
import QuickLook

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
        addLongPressMenu()
        
        fileImageView.setWidth(40)
        fileImageView.setHeight(40)
        messageLabel.pinCenterY(messageContainerView.centerYAnchor)
        messageLabel.pinLeft(fileImageView.trailingAnchor, 5)
        messageLabel.pinRight(messagesCollectionView.trailingAnchor, 5)
        messageLabel.setWidth(200)
        messageLabel.numberOfLines = 1
        messageLabel.lineBreakMode = .byTruncatingMiddle
        
        guard case .text(let stringURL) = message.kind else { return }
        guard let localURL = URL(string: stringURL) else { return }
        if localURL.pathExtension == "" {
            let components = stringURL.components(separatedBy: "#")
            guard let s3URL = URL(string: components[0]) else { return }
            let fileName = components[1]
            let mimeType = components[2]
            updateFileIcon(for: mimeType)
            
            if let localURL = FileCacheManager.shared.getFile(s3URL) {
                fileURL = localURL
                messageLabel.text = localURL.lastPathComponent
            } else {
                FileCacheManager.shared.saveFile(s3URL, fileName, mimeType) { [weak self] localURL in
                    DispatchQueue.main.async {
                        guard let localURL = localURL,
                              let self = self else { return }
                        self.fileURL = localURL
                        self.messageLabel.text = localURL.lastPathComponent
                    }
                }
            }
        } else {
            fileURL = localURL
            updateFileIcon(for: localURL.pathExtension)
            messageLabel.text = localURL.lastPathComponent
        }
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
    
    private func addLongPressMenu() {
        let interaction = UIContextMenuInteraction(delegate: self)
        messageContainerView.addInteraction(interaction)
        messageContainerView.isUserInteractionEnabled = true
    }
    
    private func open(_ url: URL) {
        DispatchQueue.main.async {
            let previewController = QLPreviewController()
            previewController.dataSource = self
            if QLPreviewController.canPreview(url as QLPreviewItem) {
                self.getRootViewController()?.present(previewController, animated: true)
            } else {
                print("QuickLook dont support this file")
                self.openInExternalApp(url)
            }
        }
    }
    
    private func openInExternalApp(_ url: URL) {
        let documentController = UIDocumentInteractionController(url: url)
        documentController.delegate = self
        documentController.presentPreview(animated: true)
    }
    
    private func updateFileIcon(for fileExtension: String) {
        let ext = fileExtension.lowercased()
        switch ext {
        case "pdf":
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
        case "epub":
            fileImageView.image = UIImage(systemName: "book.fill")
        default:
            fileImageView.image = UIImage(systemName: "document.circle.fill")
        }
    }
    
    @objc private func handleFileIconTap() {
        guard let fileURL = fileURL else { return }
        open(fileURL)
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
        return CGSize(width: 250, height: 60)
    }
    
}

extension FileMessageCell: UIContextMenuInteractionDelegate {
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
            
            return UIMenu(title: "", children: [copy, reactions, reply, load, forward, deleteMenu])
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

extension FileMessageCell: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
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

extension FileMessageCell: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURL! as QLPreviewItem
    }
}
