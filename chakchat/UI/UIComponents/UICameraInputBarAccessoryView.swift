//
//  UICameraInputBarAccessoryView.swift
//  chakchat
//
//  Created by Кирилл Исаев on 08.04.2025.
//

import InputBarAccessoryView
import UIKit
import PhotosUI
import CropViewController

protocol CameraInputBarAccessoryViewDelegate: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith attachments: [AttachmentManager.Attachment])
}

extension CameraInputBarAccessoryViewDelegate {
    func inputBar(_: InputBarAccessoryView, didPressSendButtonWith _: [AttachmentManager.Attachment]) { }
}

// MARK: - CameraInputBarAccessoryView

class CameraInputBarAccessoryView: InputBarAccessoryView, CropViewControllerDelegate, UIDocumentPickerDelegate {
    // MARK: Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Internal
    
    lazy var attachmentManager: AttachmentManager = { [unowned self] in
        let manager = AttachmentManager()
        manager.delegate = self
        return manager
    }()
    
    func configure() {
        let camera = makeButton(named: "ic_camera")
        camera.tintColor = .darkGray
        camera.onTouchUpInside { [weak self] _ in
            self?.showImagePickerControllerActionSheet()
        }
        setLeftStackViewWidthConstant(to: 35, animated: true)
        setStackViewItems([camera], forStack: .left, animated: false)
        inputPlugins = [attachmentManager]
    }
    
    override func didSelectSendButton() {
        if attachmentManager.attachments.count > 0 {
            (delegate as? CameraInputBarAccessoryViewDelegate)?
                .inputBar(self, didPressSendButtonWith: attachmentManager.attachments)
        }
        else {
            delegate?.inputBar(self, didPressSendButtonWith: inputTextView.text)
        }
    }
    
    // MARK: Private
    
    private func makeButton(named _: String) -> InputBarButtonItem {
        InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(10)
                $0.image = UIImage(systemName: "paperclip")?.withRenderingMode(.alwaysTemplate)
                $0.setSize(CGSize(width: 35, height: 35), animated: false)
            }.onSelected {
                $0.tintColor = .systemBlue
            }.onDeselected {
                $0.tintColor = UIColor.lightGray
            }.onTouchUpInside { _ in
                print("Item Tapped")
            }
    }
}

// MARK: UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension CameraInputBarAccessoryView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @objc
    func showImagePickerControllerActionSheet() {
        let file = UIAlertAction(title: "Choose from files", style: .default) { [weak self] _ in
            self?.showDocumentsPicker()
        }
        
        let photoLibraryAction = UIAlertAction(title: "Choose From Library", style: .default) { [weak self] _ in
            self?.showImagePickerController(sourceType: .photoLibrary)
        }
        
        let cameraAction = UIAlertAction(title: "Take From Camera", style: .default) { [weak self] _ in
            self?.showImagePickerController(sourceType: .camera)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        let alert = UIAlertController(title: "Choose visual", message: nil, preferredStyle: .actionSheet)
        alert.addAction(file)
        alert.addAction(photoLibraryAction)
        alert.addAction(cameraAction)
        alert.addAction(cancelAction)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        rootViewController.present(alert, animated: true, completion: nil)
    }
    
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        let imgPicker = UIImagePickerController()
        imgPicker.delegate = self
        imgPicker.sourceType = sourceType
        imgPicker.presentationController?.delegate = self
        imgPicker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        inputAccessoryView?.isHidden = true
        getRootViewController()?.present(imgPicker, animated: true, completion: nil)
    }
    
    func showDocumentsPicker() {
        let documentPicker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.item], asCopy: true
        )
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        getRootViewController()?.present(documentPicker, animated: true)
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
    {
        picker.dismiss(animated: true) {
            if let image = info[.originalImage] as? UIImage {
                self.showCrop(image)
            }
            if let videoURL = info[.mediaURL] as? URL {
                let nsURL = videoURL as NSURL
                self.inputPlugins.forEach {_ = $0.handleInput(of: nsURL)}
                self.inputAccessoryView?.isHidden = false
            }
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }
        handleSelectedFile(selectedFileURL)
    }
    
    private func handleSelectedFile(_ url: URL) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: url, to: destinationURL)
            print("File saved: \(destinationURL)")
            
            self.inputPlugins.forEach { _ = $0.handleInput(of: url as NSURL)}
        } catch {
            debugPrint("failed to get file data in camera input bar accessory view")
        }
    }
    
    private func generateThumbnail(for videoURL: URL) -> UIImage {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try generator.copyCGImage(at: CMTime(seconds: 1, preferredTimescale: 60), actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return UIImage(systemName: "play.circle.fill")!
        }
    }
    
    private func showCrop(_ image: UIImage) {
        let vc = CropViewController(croppingStyle: .default, image: image)
        vc.aspectRatioPreset = .presetSquare
        vc.aspectRatioLockEnabled = true
        vc.toolbarPosition = .top
        vc.doneButtonTitle = "Continue"
        vc.cancelButtonTitle = "Back"
        vc.delegate = self
        getRootViewController()?.present(vc, animated: true)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        inputPlugins.forEach { _ = $0.handleInput(of: image) }
        cropViewController.dismiss(animated: true) {
            self.inputAccessoryView?.isHidden = false
        }
    }
    
    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        getRootViewController()?.dismiss(animated: true, completion: nil)
        inputAccessoryView?.isHidden = false
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

// MARK: AttachmentManagerDelegate

extension CameraInputBarAccessoryView: AttachmentManagerDelegate {
    // MARK: - AttachmentManagerDelegate
    
    func attachmentManager(_: AttachmentManager, shouldBecomeVisible: Bool) {
        setAttachmentManager(active: shouldBecomeVisible)
    }
    
    func attachmentManager(_ manager: AttachmentManager, didReloadTo _: [AttachmentManager.Attachment]) {
        sendButton.isEnabled = manager.attachments.count > 0
    }
    
    func attachmentManager(_ manager: AttachmentManager, didInsert _: AttachmentManager.Attachment, at _: Int) {
        sendButton.isEnabled = manager.attachments.count > 0
    }
    
    func attachmentManager(_ manager: AttachmentManager, didRemove _: AttachmentManager.Attachment, at _: Int) {
        sendButton.isEnabled = manager.attachments.count > 0
    }
    
    func attachmentManager(_: AttachmentManager, didSelectAddAttachmentAt _: Int) {
        showImagePickerControllerActionSheet()
    }
    
    // MARK: - AttachmentManagerDelegate Helper
    
    func setAttachmentManager(active: Bool) {
        let topStackView = topStackView
        if active, !topStackView.arrangedSubviews.contains(attachmentManager.attachmentView) {
            topStackView.insertArrangedSubview(attachmentManager.attachmentView, at: topStackView.arrangedSubviews.count)
            topStackView.layoutIfNeeded()
        } else if !active, topStackView.arrangedSubviews.contains(attachmentManager.attachmentView) {
            topStackView.removeArrangedSubview(attachmentManager.attachmentView)
            topStackView.layoutIfNeeded()
        }
    }
}

// MARK: UIAdaptivePresentationControllerDelegate

extension CameraInputBarAccessoryView: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerWillDismiss(_: UIPresentationController) {
        isHidden = false
    }
}
