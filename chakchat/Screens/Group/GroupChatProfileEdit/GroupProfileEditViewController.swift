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
        static let cornerRadius: CGFloat = 50
        static let iconImageViewTop: CGFloat = 0
        static let nameTop: CGFloat = 2
        static let usernameTop: CGFloat = 2.5
        static let phoneTop: CGFloat = 2.5
        static let fieldsLeading: CGFloat = 0
        static let fieldsTrailing: CGFloat = 0
        static let defaultText: String = "default"
        static let borderWidth: CGFloat = 5
        static let maxGroupNameLength: Int = 50
    }
    
    // MARK: - Properties
    private var iconImageView: UIImageView = UIImageView()
    private var groupNameTextField: UIProfileTextField = UIProfileTextField(title: "Name", placeholder: "Name", isEditable: true)
    private var groupDescriptionTextField: UIProfileTextField = UIProfileTextField(title: "Description", placeholder: "Description", isEditable: true)
    private let interactor: GroupProfileEditBusinessLogic
    private let clearButton: UIButton = UIButton(type: .system)
    private var photoMenu: UIMenu = UIMenu(children: [])
    private var isImageSet: Bool = false
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        interactor.passChatData()
    }
    
    // MARK: - User Data Configuration
    public func configureWithData(_ chatData: GroupProfileEditModels.ProfileData) {
        let color = UIColor.random()
        let image = UIImage.imageWithText(
            text: chatData.name,
            size: CGSize(width: Constants.iconImageSize, height: Constants.iconImageSize),
            color: color,
            borderWidth: Constants.borderWidth
        )
        iconImageView.image = image
        groupNameTextField.setText(chatData.name)
        groupDescriptionTextField.setText(chatData.description)
        if let photoURL = chatData.photoURL {
            let image = ImageCacheManager.shared.getImage(for: photoURL as NSURL)
            iconImageView.image = image
            iconImageView.layer.cornerRadius = Constants.cornerRadius
        }
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.backgroundSettings
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        configureIconImageView()
        configureClearButtonOnImage()
        configureNameTextField()
        configureUsernameTextField()
        
        configureCancelButton()
        configureApplyButton()
    }
    
    private func configureCancelButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizationManager.shared.localizedString(for: "cancel"), style: .plain, target: self, action: #selector(cancelButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.lightOrange
    }
    
    private func configureApplyButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: LocalizationManager.shared.localizedString(for: "apply"), style: .plain, target: self, action: #selector(applyButtonPressed))
        navigationItem.rightBarButtonItem?.tintColor = Colors.lightOrange
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    private func configureIconImageView() {
        view.addSubview(iconImageView)
        iconImageView.setHeight(Constants.iconImageSize)
        iconImageView.setWidth(Constants.iconImageSize)
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.layer.cornerRadius = Constants.cornerRadius
        iconImageView.layer.masksToBounds = true
        
        iconImageView.pinCenterX(view)
        iconImageView.pinTop(view.safeAreaLayoutGuide.topAnchor, Constants.iconImageViewTop)
        
        iconImageView.tintColor = Colors.lightOrange
        
        iconImageView.isUserInteractionEnabled = true
    }
    
    private func configureNameTextField() {
        view.addSubview(groupNameTextField)
        groupNameTextField.pinTop(iconImageView.bottomAnchor, Constants.nameTop)
        groupNameTextField.pinLeft(view.leadingAnchor, Constants.fieldsLeading)
        groupNameTextField.pinRight(view.trailingAnchor, Constants.fieldsTrailing)
        groupNameTextField.setText(LocalizationManager.shared.localizedString(for: "error"))
        groupNameTextField.textField.delegate = self
    }
    
    private func configureUsernameTextField() {
        view.addSubview(groupDescriptionTextField)
        groupDescriptionTextField.pinTop(groupNameTextField.bottomAnchor, Constants.usernameTop)
        groupDescriptionTextField.pinLeft(view.leadingAnchor, Constants.fieldsLeading)
        groupDescriptionTextField.pinRight(view.trailingAnchor, Constants.fieldsTrailing)
        groupDescriptionTextField.setText(LocalizationManager.shared.localizedString(for: "error"))
    }
    
    private func configureClearButtonOnImage() {
        iconImageView.layoutIfNeeded()

        clearButton.frame = iconImageView.bounds
        clearButton.backgroundColor = .clear
        clearButton.layer.cornerRadius = iconImageView.layer.cornerRadius
        clearButton.layer.masksToBounds = true

        iconImageView.addSubview(clearButton)
        
        let editAction = UIAction(
            title: LocalizationManager.shared.localizedString(for: "edit"),
            image: UIImage(systemName: "pencil")
        ) { action in
            self.chooseImage()
        }
        photoMenu = UIMenu(children: [editAction])
        clearButton.menu = photoMenu
        clearButton.showsMenuAsPrimaryAction = true
    }
    
    private func chooseImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func sendDeleteImage() {
        guard iconImageView.image != nil else {
            return
        }
        configureIconImageView()
        let color = UIColor.random()
        let image = UIImage.imageWithText(
            text: groupNameTextField.getText() ?? "",
            size: CGSize(width: Constants.iconImageSize, height: Constants.iconImageSize),
            color: color,
            borderWidth: Constants.borderWidth
        )
        iconImageView.image = image
        configureClearButtonOnImage()
        isImageSet = false
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
        if isImageSet, let image = iconImageView.image {
            interactor.updateGroupPhoto(image)
        }
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
            isImageSet = true
        }
        let deleteAction = UIAction(
            title: LocalizationManager.shared.localizedString(for: "delete"),
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { action in
            self.sendDeleteImage()
        }
        if photoMenu.children.count == 1 {
            var updatedChildren = photoMenu.children
            updatedChildren.append(deleteAction)
            photoMenu = photoMenu.replacingChildren(updatedChildren)
            clearButton.menu = photoMenu
            clearButton.showsMenuAsPrimaryAction = true
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension GroupProfileEditViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        var newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        let result = newText.count <= Constants.maxGroupNameLength
        if !result {
            newText = String(newText.prefix(Constants.maxGroupNameLength))
        }
        
        return result
    }
}
