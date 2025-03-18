//
//  ProfileSettingsViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.01.2025.
//

import UIKit
import Combine
import OSLog

// MARK: - ProfileSettingsViewController
final class ProfileSettingsViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let defaultProfileImageSymbol: String = "camera.circle"
        static let iconImageSize: CGFloat = 100
        static let borderWidth: CGFloat = 5
        static let iconImageViewTop: CGFloat = 0
        static let nameTop: CGFloat = 2
        static let usernameTop: CGFloat = 2.5
        static let phoneTop: CGFloat = 2.5
        static let fieldsLeading: CGFloat = 0
        static let fieldsTrailing: CGFloat = 0
        static let defaultText: String = "default"
        
        static let logOutButtonRadius: CGFloat = 18
        static let logOutButtonTop: CGFloat = 25
        static let logOutButtonHeight: CGFloat = 38
        static let logOutButtonWidth: CGFloat = 100
        static let logOutBorderWidth: CGFloat = 1
        
        static let dateButtonTop: CGFloat = 2.5
        static let dateButtonX: CGFloat = 20
        static let dateButtonHeight: CGFloat = 50
        
        static let birthTextFieldTop: CGFloat = 2.5
        static let birthTextFieldLeading: CGFloat = 0
        static let birthTextFieldTrailing: CGFloat = 0
        static let cornerRadius: CGFloat = 50
    }
    
    // MARK: - Properties
    private lazy var iconImageView: UIImageView = UIImageView()
    private var nameTextField: UIProfileTextField = UIProfileTextField(title: "name", placeholder: "name", isEditable: true)
    private var usernameTextField: UIProfileTextField = UIProfileTextField(title: "username", placeholder: "username", isEditable: true)
    private var phoneTextField: UIProfileTextField = UIProfileTextField(title: "phone", placeholder: "phone", isEditable: false)
    private var birthTextField: UIProfileTextField = UIProfileTextField(title: "date_of_birth", placeholder: "choose", isEditable: false)
    private var logOutButton: UIButton = UIButton(type: .system)
    private var dateButton: UIButton = UIButton(type: .system)
    private let dateFormatter: DateFormatter = DateFormatter()
    let interactor: ProfileSettingsScreenBusinessLogic
    private var cancellables = Set<AnyCancellable>()
    private var nameIndicator: UIImageView = UIImageView()
    private var usernameIndicator: UIImageView = UIImageView()
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var selectedDate: Date?
    private var imageURL: URL?
    private let isNicknameCorrect = CurrentValueSubject<Bool, Never>(true)
    private let isApplyEnabled = CurrentValueSubject<Bool, Never>(true)
    private var photoMenu: UIMenu = UIMenu(children: [])
    private let clearButton: UIButton = UIButton(type: .system)
    
    
    // MARK: - Initialization
    init(interactor: ProfileSettingsScreenBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: .languageDidChange, object: nil)
        interactor.loadUserData()
    }
    
    // MARK: - Changing image color
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            guard let text = nameTextField.getText() else { return }
            let image = UIProfilePhoto(text, Constants.iconImageSize, Constants.borderWidth).getPhoto()
            iconImageView.image = image
        }
    }
    
    // MARK: - Public Methods
    func configureUserData(_ userData: ProfileSettingsModels.ProfileUserData) {
        nameTextField.setText(userData.name)
        usernameTextField.setText(userData.username)
        let formattedPhone = Format.number(userData.phone)
        phoneTextField.setText(formattedPhone)
        if let birth = userData.dateOfBirth {
            dateFormatter.dateFormat = UIConstants.dateFormat
            selectedDate = dateFormatter.date(from: birth)
            birthTextField.setText(birth)
        }
        let editAction = UIAction(
            title: LocalizationManager.shared.localizedString(for: "edit"),
            image: UIImage(systemName: "pencil")
        ) { action in
            self.chooseImage()
        }
        let deleteAction = UIAction(
            title: LocalizationManager.shared.localizedString(for: "delete"),
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { action in
            self.sendDeleteImageRequest()
        }
        if let photoURL = userData.photo {
            let image = ImageCacheManager.shared.getImage(for: photoURL as NSURL)
            iconImageView.image = image
            iconImageView.layer.cornerRadius = 50
            photoMenu = UIMenu(children: [editAction, deleteAction])
            clearButton.menu = photoMenu
            clearButton.showsMenuAsPrimaryAction = true
        } else {
            let image = UIProfilePhoto(userData.name, Constants.iconImageSize, Constants.borderWidth).getPhoto()
            iconImageView.layer.cornerRadius = 50
            iconImageView.image = image
            photoMenu = UIMenu(children: [editAction])
            clearButton.menu = photoMenu
            clearButton.showsMenuAsPrimaryAction = true
        }
    }
    
    func deleteImage() {
        guard let text = nameTextField.getText() else { return }
        let image = UIProfilePhoto(text, Constants.iconImageSize, Constants.borderWidth).getPhoto()
        iconImageView.image = image
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
        configurePhoneTextField()
        configureBirthTextField()
        configureDateButton()
        
        configureCancelButton()
        configureApplyButton()
        configureLogOutButton()
        
        bindDynamicCheck()
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
        iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
        iconImageView.layer.masksToBounds = true
        
        iconImageView.pinCenterX(view)
        iconImageView.pinTop(view.safeAreaLayoutGuide.topAnchor, Constants.iconImageViewTop)
        iconImageView.tintColor = Colors.lightOrange
        
        iconImageView.isUserInteractionEnabled = true
    }
    
    private func configureClearButtonOnImage() {
        iconImageView.layoutIfNeeded()

        clearButton.frame = iconImageView.bounds
        clearButton.backgroundColor = .clear
        clearButton.layer.cornerRadius = iconImageView.layer.cornerRadius
        clearButton.layer.masksToBounds = true

        iconImageView.addSubview(clearButton)
    }

    private func configureNameTextField() {
        view.addSubview(nameTextField)
        nameTextField.addSubview(nameIndicator)
        nameTextField.pinTop(iconImageView.bottomAnchor, Constants.nameTop)
        nameTextField.pinLeft(view.leadingAnchor, Constants.fieldsLeading)
        nameTextField.pinRight(view.trailingAnchor, Constants.fieldsTrailing)
        nameTextField.setText(LocalizationManager.shared.localizedString(for: "error"))
        nameIndicator.image = nil
        nameIndicator.pinCenterY(nameTextField)
        nameIndicator.pinRight(nameTextField.trailingAnchor, 20)
    }
    
    private func configureUsernameTextField() {
        view.addSubview(usernameTextField)
        usernameTextField.addSubview(activityIndicator)
        usernameTextField.addSubview(usernameIndicator)
        usernameTextField.pinTop(nameTextField.bottomAnchor, Constants.usernameTop)
        usernameTextField.pinLeft(view.leadingAnchor, Constants.fieldsLeading)
        usernameTextField.pinRight(view.trailingAnchor, Constants.fieldsTrailing)
        usernameTextField.setText(LocalizationManager.shared.localizedString(for: "error"))
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        activityIndicator.pinCenterY(usernameTextField)
        activityIndicator.pinRight(usernameTextField.trailingAnchor, 20)
        
        usernameIndicator.image = nil
        usernameIndicator.pinCenterY(usernameTextField)
        usernameIndicator.pinRight(usernameTextField.trailingAnchor, 20)
   
    }
 
    private func configurePhoneTextField() {
        view.addSubview(phoneTextField)
        phoneTextField.pinTop(usernameTextField.bottomAnchor, Constants.phoneTop)
        phoneTextField.pinLeft(view.leadingAnchor, Constants.fieldsLeading)
        phoneTextField.pinRight(view.trailingAnchor, Constants.fieldsTrailing)
        phoneTextField.setText(LocalizationManager.shared.localizedString(for: "error"))
    }
    
    private func configureBirthTextField() {
        view.addSubview(birthTextField)
        birthTextField.pinTop(phoneTextField.bottomAnchor, Constants.birthTextFieldTop)
        birthTextField.pinLeft(view.leadingAnchor, Constants.birthTextFieldLeading)
        birthTextField.pinRight(view.trailingAnchor, Constants.birthTextFieldTrailing)
    }
    
    private func configureLogOutButton() {
        logOutButton.setTitle(LocalizationManager.shared.localizedString(for: "log_out"), for: .normal)
        logOutButton.setTitleColor(.systemRed, for: .normal)
        logOutButton.titleLabel?.font = Fonts.systemB20
        logOutButton.backgroundColor = .clear
        logOutButton.layer.cornerRadius = Constants.logOutButtonRadius
        logOutButton.layer.borderWidth = Constants.logOutBorderWidth
        logOutButton.layer.borderColor = UIColor.systemRed.cgColor
        logOutButton.addTarget(self, action: #selector(logOutButtonPressed), for: .touchUpInside)
        logOutButton.setHeight(Constants.logOutButtonHeight)
        logOutButton.setWidth(Constants.logOutButtonWidth)
        
        view.addSubview(logOutButton)
        logOutButton.pinCenterX(view)
        logOutButton.pinTop(dateButton.bottomAnchor, Constants.logOutButtonTop)
    }
    
    private func configureDateButton() {
        view.addSubview(dateButton)
        dateButton.pinTop(phoneTextField.bottomAnchor, Constants.dateButtonTop)
        dateButton.pinLeft(view.leadingAnchor, Constants.dateButtonX)
        dateButton.pinRight(view.trailingAnchor, Constants.dateButtonX)
        dateButton.setHeight(Constants.dateButtonHeight)
        dateButton.addTarget(self, action: #selector(dateButtonPressed), for: .touchUpInside)
    }
    
    // MARK: - Supporting Methods
    private func transferUserProfileData() throws -> ProfileSettingsModels.ChangeableProfileUserData {
        guard let newNickname = nameTextField.getText() else {
            throw CriticalError.noData
        }
        guard let newUsername = usernameTextField.getText() else {
            throw CriticalError.noData
        }
        if let newBirth = birthTextField.getText() {
            let date = dateFormatter.date(from: newBirth)
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let bToRequest = dateFormatter.string(from: date ?? Date())
            return ProfileSettingsModels.ChangeableProfileUserData(
                name: newNickname,
                username: newUsername,
                dateOfBirth: bToRequest
            )
        }
        return ProfileSettingsModels.ChangeableProfileUserData(
            name: newNickname,
            username: newUsername,
            dateOfBirth: nil
        )

    }
    
    private func bindDynamicCheck() {
        let validator = SignupDataValidator()
        let nicknamePublisher = nameTextField.textField.textPublisher
        
        let isNameInputValid = nicknamePublisher
            .map { text in
                return validator.validateName(text)
            }
        
        isNameInputValid
            .sink { [weak self] isValid in
                self?.isNicknameCorrect.send(isValid)
                self?.nameIndicator.image = isValid
                ? UIImage(systemName: "checkmark.circle.fill")
                : UIImage(systemName: "xmark.circle.fill")
                
                self?.nameTextField.layer.borderColor = isValid
                ? CGColor(red: 0, green: 255, blue: 0, alpha: 1)
                : CGColor(red: 255, green: 0, blue: 0, alpha: 1)
                
                self?.nameIndicator.tintColor = isValid
                ? .systemGreen
                : .systemRed
    
            }.store(in: &cancellables)
        
        usernameTextField.textField.textPublisher
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] username in
                guard let self = self else { return }
                let isUsernameValid = validator.validateUsername(username)
                DispatchQueue.main.async {
                    if !isUsernameValid {
                        self.usernameIndicator.image = UIImage(systemName: "xmark.circle.fill")
                        self.usernameIndicator.tintColor = .systemRed
                        self.activityIndicator.stopAnimating()
                        self.isApplyEnabled.send(false)
                    } else {
                        self.usernameIndicator.image = nil
                    }
                }
            })
            .filter { [validator] username in
                validator.validateUsername(username)
            }
            .flatMap { [weak self] username -> AnyPublisher<Result<ProfileSettingsModels.ProfileUserData, Error>, Never> in
                guard let self = self else { return Empty().eraseToAnyPublisher() }
                DispatchQueue.main.async {
                    self.activityIndicator.startAnimating()
                    self.usernameIndicator.isHidden = true
                }
                
                return Future { promise in
                    self.interactor.checkUsername(username) { result in
                        promise(.success(result))
                    }
                }
                .handleEvents(receiveCompletion: { _ in
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.usernameIndicator.isHidden = false
                    }
                })
                .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.activityIndicator.stopAnimating()
                self?.usernameIndicator.isHidden = false
                switch result {
                case .success(_):
                    self?.usernameIndicator.image = UIImage(systemName:  "xmark.circle.fill")
                    self?.usernameIndicator.tintColor = .systemRed
                    self?.isApplyEnabled.send(false)
                case .failure(let error):
                    if let err = error as? APIErrorResponse {
                        if err.errorType == ApiErrorType.notFound.rawValue {
                            self?.usernameIndicator.image = UIImage(systemName: "checkmark.circle.fill")
                            self?.usernameIndicator.tintColor = .systemGreen
                            self?.isApplyEnabled.send(true)
                        }
                    }
                }
            }.store(in: &cancellables)
        
        Publishers.CombineLatest(isNicknameCorrect, isApplyEnabled)
            .map { $0 && $1 }
            .sink { [weak self] isEnabled in
                self?.navigationItem.rightBarButtonItem?.isEnabled = isEnabled
            }
            .store(in: &cancellables)
    }
    
    private func chooseImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func sendDeleteImageRequest() {
        guard iconImageView.image != nil else {
            return
        }
        interactor.deleteProfilePhoto()
    }
    
    // MARK: - Actions
    @objc
    private func cancelButtonPressed() {
        interactor.backToSettingsMenu()
    }
    
    @objc
    private func applyButtonPressed() {
        do {
            let newData = try transferUserProfileData()
            interactor.putNewData(newData)
            if let image = iconImageView.image {
                interactor.putProfilePhoto(image)
            }
        } catch CriticalError.noData {
            print("Critical error")
        } catch {
            print("Unknown error")
        }
    }
    
    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc
    private func logOutButtonPressed() {
        // TODO: show alert "Are u sure?" and log out of from account.
        UIView.animate(withDuration: UIConstants.animationDuration, animations: {
            self.logOutButton.transform = CGAffineTransform(scaleX: UIConstants.buttonScale, y: UIConstants.buttonScale)
            }, completion: { _ in
            UIView.animate(withDuration: UIConstants.animationDuration) {
                self.logOutButton.transform = CGAffineTransform.identity
            }
        })
        interactor.signOut()
    }
    
    @objc
    private func dateButtonPressed() {
        let datePicker: UICustomDatePicker = UICustomDatePicker()
        view.addSubview(datePicker)
        datePicker.pinTop(view.topAnchor, 0)
        datePicker.pinLeft(view.leadingAnchor, 0)
        datePicker.pinRight(view.trailingAnchor, 0)
        datePicker.pinBottom(view.bottomAnchor, 0)
        view.bringSubviewToFront(datePicker)
        datePicker.settedDate = selectedDate ?? Date()
        datePicker.title = LocalizationManager.shared.localizedString(for: "date_of_birth")
        datePicker.pinSuperView(view)
        datePicker.delegate = { [weak self] date in
            self?.handleDateSelection(date)
        }
    }
    
    @objc
    private func languageDidChange() {
        navigationItem.rightBarButtonItem?.title = LocalizationManager.shared.localizedString(for: "apply")
        navigationItem.leftBarButtonItem?.title = LocalizationManager.shared.localizedString(for: "cancel")
        logOutButton.titleLabel?.text = LocalizationManager.shared.localizedString(for: "log_out")
        nameTextField.localize()
        usernameTextField.localize()
        phoneTextField.localize()
        birthTextField.localize()
    }
    
    // TODO: - Probably it is interactor logic
    private func handleDateSelection(_ date: Date?) {
        if let date = date {
            print("Selected Date: \(date)")
            dateFormatter.dateFormat = UIConstants.dateFormat
            let formattedDate = dateFormatter.string(from: date)
            selectedDate = date
            birthTextField.setText(formattedDate)
        } else {
            print("Date selection was reset")
            selectedDate = nil
            birthTextField.setText(nil)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension ProfileSettingsViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            iconImageView.image = pickedImage
            iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
        }
        let deleteAction = UIAction(
            title: LocalizationManager.shared.localizedString(for: "delete"),
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { action in
            self.sendDeleteImageRequest()
        }
        var updatedChildren = photoMenu.children
        updatedChildren.append(deleteAction)
        photoMenu = photoMenu.replacingChildren(updatedChildren)
        clearButton.menu = photoMenu
        clearButton.showsMenuAsPrimaryAction = true
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

enum CriticalError: Error {
    case noData
}
