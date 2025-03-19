//
//  GroupProfileEditViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit
import OSLog
final class GroupProfileEditViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let defaultProfileImageSymbol: String = "camera.circle"
        static let iconImageSize: CGFloat = 100
        static let iconImageViewTop: CGFloat = 0
        static let nameTop: CGFloat = 2
        static let usernameTop: CGFloat = 2.5
        static let phoneTop: CGFloat = 2.5
        static let fieldsLeading: CGFloat = 0
        static let fieldsTrailing: CGFloat = 0
        static let defaultText: String = "default"
        static let borderWidth: CGFloat = 5
    }
    
    // MARK: - Properties
    private var iconImageView: UIImageView = UIImageView()
    private var groupNameTextField: UIProfileTextField = UIProfileTextField(title: "Name", placeholder: "Name", isEditable: true)
    private var groupDescriptionTextField: UIProfileTextField = UIProfileTextField(title: "Description", placeholder: "Description", isEditable: true)
    let interactor: GroupProfileEditBusinessLogic
    
    // MARK: - Initialization
    init(interactor: GroupProfileEditBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        interactor.passChatData()
    }
    
    // MARK: - User Data Configuration
    public func configureWithData(_ chatData: GroupProfileEditModels.ProfileData) {
        let color = UIColor.random()
        let image = UIImage.imageWithText(
            text: chatData.name,
            size: CGSize(width: Constants.iconImageSize, height: Constants.iconImageSize),
            backgroundColor: Colors.backgroundSettings,
            textColor: color,
            borderColor: color,
            borderWidth: Constants.borderWidth
        )
        iconImageView.image = image
        groupNameTextField.setText(chatData.name)
        groupDescriptionTextField.setText(chatData.description)
        if let photoURL = chatData.photoURL {
            let image = ImageCacheManager.shared.getImage(for: photoURL as NSURL)
            iconImageView.image = image
            iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
        }
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.backgroundSettings
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        configureIconImageView(nil)
        configureNameTextField()
        configureUsernameTextField()
        
        configureCancelButton()
        configureApplyButton()
    }
    
    // MARK: - Cancel Button Configuration
    private func configureCancelButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizationManager.shared.localizedString(for: "cancel"), style: .plain, target: self, action: #selector(cancelButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.lightOrange
    }
    
    // MARK: - Apply Button Configuration
    private func configureApplyButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: LocalizationManager.shared.localizedString(for: "apply"), style: .plain, target: self, action: #selector(applyButtonPressed))
        navigationItem.rightBarButtonItem?.tintColor = Colors.lightOrange
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    // MARK: - Icon ImageView Configuration
    private func configureIconImageView(_ image: UIImage?) {
        view.addSubview(iconImageView)
        iconImageView.setHeight(Constants.iconImageSize)
        iconImageView.setWidth(Constants.iconImageSize)
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
        iconImageView.layer.masksToBounds = true
        
        iconImageView.pinCenterX(view)
        iconImageView.pinTop(view.safeAreaLayoutGuide.topAnchor, Constants.iconImageViewTop)
        
        iconImageView.tintColor = Colors.lightOrange
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(iconImageViewTapped))
        iconImageView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Name Text Field Configuration
    private func configureNameTextField() {
        view.addSubview(groupNameTextField)
        groupNameTextField.pinTop(iconImageView.bottomAnchor, Constants.nameTop)
        groupNameTextField.pinLeft(view.leadingAnchor, Constants.fieldsLeading)
        groupNameTextField.pinRight(view.trailingAnchor, Constants.fieldsTrailing)
        groupNameTextField.setText(LocalizationManager.shared.localizedString(for: "error"))
    }
    
    // MARK: - Username Text Field Configuration
    private func configureUsernameTextField() {
        view.addSubview(groupDescriptionTextField)
        groupDescriptionTextField.pinTop(groupNameTextField.bottomAnchor, Constants.usernameTop)
        groupDescriptionTextField.pinLeft(view.leadingAnchor, Constants.fieldsLeading)
        groupDescriptionTextField.pinRight(view.trailingAnchor, Constants.fieldsTrailing)
        groupDescriptionTextField.setText(LocalizationManager.shared.localizedString(for: "error"))
    }
    
    // MARK: - Actions
    @objc
    private func cancelButtonPressed() {
        interactor.routeBack()
    }
    
    @objc
    private func applyButtonPressed() {
        if let name = groupNameTextField.getText() {
            interactor.updateChat(name, groupDescriptionTextField.getText())
        }
        if let image = iconImageView.image {
            interactor.updateGroupPhoto(image)
        }
    }
    
    @objc
    private func iconImageViewTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension GroupProfileEditViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            iconImageView.image = pickedImage
            iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
