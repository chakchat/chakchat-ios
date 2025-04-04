//
//  SignupViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.01.2025.
//

import UIKit
import Combine

// MARK: - SignupViewController
final class SignupViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let inputButtonHeight: CGFloat = 50
        static let inputButtonWidth: CGFloat = 200
        static let inputButtonTopAnchor: CGFloat = 40
        static let inputButtonGradientColor: [CGColor] = [UIColor.yellow.cgColor, UIColor.orange.cgColor]
        
        static let inputButtonGradientStartPoint: CGPoint = CGPoint(x: 0.0, y: 0.5)
        static let inputButtonGradientEndPoint: CGPoint = CGPoint(x: 1, y: 0.5)
        static let inputButtonGradientCornerRadius: CGFloat = 25
        
        static let namePaddingX: CGFloat = 0
        static let namePaddingY: CGFloat = 0
        static let nameLeftPaddingWidth: CGFloat = 10
        static let nameRightPaddingWidth: CGFloat = 40
        static let nameTextFieldTop: CGFloat = 40
        static let nameTextFieldHeight: CGFloat = 50
        static let nameTextFieldWidth: CGFloat = 300
        
        static let borderCornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 1
        
        static let usernamePaddingX: CGFloat = 0
        static let usernamePaddingY: CGFloat = 0
        static let usernamePaddingWidth: CGFloat = 10
        static let usernameTextFieldTop: CGFloat = 20
        static let usernameTextFieldHeight: CGFloat = 50
        static let usernameTextFieldWidth: CGFloat = 300
        
        static let createButtonHeight: CGFloat = 38
        static let createButtonWidth: CGFloat = 228
        
        static let alphaStart: CGFloat = 0
        static let alphaEnd: CGFloat = 1
        static let errorLabelFontSize: CGFloat = 18
        static let errorLabelTop: CGFloat = -8
        static let errorDuration: TimeInterval = 0.5
        static let errorMessageDuration: TimeInterval = 2
        static let maxWidth: CGFloat = 310
        static let numberOfLines: Int = 2
        
        static let colorDuration: CFTimeInterval = 1.5
        static let extraKeyboardIndent: CGFloat = 16
    }
    
    // MARK: - Properties
    private let interactor: SignupBusinessLogic

    private var chakchatStackView: UIChakChatStackView = UIChakChatStackView()
    private var nameTextField: UITextField = UITextField()
    private var usernameTextField: UITextField = UITextField()
    private var sendGradientButton: UIGradientButton = UIGradientButton(title: LocalizationManager.shared.localizedString(for: "create_account"))
    private var nameIndicator: UIImageView = UIImageView()
    private var usernameIndicator: UIImageView = UIImageView()
    private var errorLabel: UIErrorLabel = UIErrorLabel(width: Constants.maxWidth, numberOfLines: Constants.numberOfLines)
    private let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    init(interactor: SignupBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: .languageDidChange, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    
    // MARK: - Public Methods
    func showError(_ message: String?) {
        if message != nil {
            errorLabel.showError(message)
        }
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.background
        configureChakChatStackView()
        configureNameTextField()
        configureUsernameTextField()
        configureInputButton()
        configurateErrorLabel()
        bindDynamicCheck()
    }
    
    private func configureChakChatStackView() {
        view.addSubview(chakchatStackView)
        chakchatStackView.pinTop(view.safeAreaLayoutGuide.topAnchor, UIConstants.chakchatStackViewTopAnchor)
        chakchatStackView.pinCenterX(view)
    }
    
    private func configureNameTextField() {
        view.addSubview(nameTextField)
        nameTextField.addSubview(nameIndicator)
        nameTextField.borderStyle = UITextField.BorderStyle.roundedRect
        nameTextField.placeholder = LocalizationManager.shared.localizedString(for: "name")
        let leftPaddingView = UIView(
            frame: CGRect(
                x: Constants.namePaddingX,
                y: Constants.namePaddingY,
                width: Constants.nameLeftPaddingWidth,
                height: nameTextField.frame.height
            )
        )
        let rightPaddingView = UIView(
            frame: CGRect(
                x: Constants.namePaddingX,
                y: Constants.namePaddingY,
                width: Constants.nameRightPaddingWidth,
                height: nameTextField.frame.height
            )
        )
        nameTextField.font = Fonts.interR20
        nameTextField.borderStyle = .none
        nameTextField.layer.cornerRadius = Constants.borderCornerRadius
        nameTextField.layer.borderWidth = Constants.borderWidth
        nameTextField.layer.borderColor = UIColor.gray.cgColor
        nameTextField.leftView = leftPaddingView
        nameTextField.rightView = rightPaddingView
        nameTextField.rightViewMode = .always
        nameTextField.leftViewMode = .always
        nameTextField.delegate = self
        nameTextField.pinTop(chakchatStackView.bottomAnchor, Constants.nameTextFieldTop)
        nameTextField.pinCenterX(view)
        nameTextField.setHeight(Constants.nameTextFieldHeight)
        nameTextField.setWidth(Constants.nameTextFieldWidth)
        nameIndicator.image = nil
        nameIndicator.pinCenterY(nameTextField)
        nameIndicator.pinRight(nameTextField.trailingAnchor, 20)
        
        nameTextField.autocorrectionType = .no
        nameTextField.spellCheckingType = .no
        nameTextField.autocapitalizationType = .none
    }
    
    private func configureUsernameTextField() {
        view.addSubview(usernameTextField)
        usernameTextField.addSubview(usernameIndicator)
        usernameTextField.borderStyle = UITextField.BorderStyle.roundedRect
        usernameTextField.placeholder = LocalizationManager.shared.localizedString(for: "username")
        let leftPaddingView = UIView(
            frame: CGRect(
                x: Constants.usernamePaddingX,
                y: Constants.usernamePaddingY,
                width: Constants.usernamePaddingWidth,
                height: usernameTextField.frame.height
            )
        )
        let rightPaddingView = UIView(
            frame: CGRect(
                x: Constants.usernamePaddingX,
                y: Constants.usernamePaddingY,
                width: Constants.nameRightPaddingWidth,
                height: usernameTextField.frame.height
            )
        )
        usernameTextField.font = Fonts.interR20
        usernameTextField.borderStyle = .none
        usernameTextField.layer.cornerRadius = Constants.borderCornerRadius
        usernameTextField.layer.borderWidth = Constants.borderWidth
        usernameTextField.layer.borderColor = UIColor.gray.cgColor
        
        usernameTextField.leftView = leftPaddingView
        usernameTextField.rightView = rightPaddingView
        usernameTextField.leftViewMode = .always
        usernameTextField.rightViewMode = .always
        usernameTextField.delegate = self
        usernameTextField.pinTop(nameTextField.bottomAnchor, Constants.usernameTextFieldTop)
        usernameTextField.pinCenterX(view)
        usernameTextField.setHeight(Constants.usernameTextFieldHeight)
        usernameTextField.setWidth(Constants.usernameTextFieldWidth)
        usernameIndicator.image = nil
        usernameIndicator.pinCenterY(usernameTextField)
        usernameIndicator.pinRight(usernameTextField.trailingAnchor, 20)
        
        usernameTextField.autocorrectionType = .no
        usernameTextField.spellCheckingType = .no
        usernameTextField.autocapitalizationType = .none
        usernameTextField.addSubview(activityIndicator)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        activityIndicator.pinCenterY(usernameTextField)
        activityIndicator.pinRight(usernameTextField.trailingAnchor, 20)
    }
    
    private func configureInputButton() {
        view.addSubview(sendGradientButton)
        sendGradientButton.pinCenterX(view)
        sendGradientButton.pinTop(usernameTextField.bottomAnchor, UIConstants.gradientButtonTopAnchor)
        sendGradientButton.setHeight(Constants.createButtonHeight)
        sendGradientButton.setWidth(Constants.createButtonWidth)
        sendGradientButton.titleLabel?.font = Fonts.systemB20
        sendGradientButton.isEnabled = false
        sendGradientButton.alpha = 0.5
        sendGradientButton.addTarget(self, action: #selector(sendButtonPressed), for: .touchUpInside)
    }
    
    private func configurateErrorLabel() {
        view.addSubview(errorLabel)
        errorLabel.pinCenterX(view)
        errorLabel.pinTop(chakchatStackView.bottomAnchor, Constants.errorLabelTop)
    }
    
    // MARK: - Supporting Methods
    private func changeColor(_ field: UITextField) {
        let originalColor = field.layer.borderColor
        UIView.animate(withDuration: Constants.colorDuration, animations: {
            field.layer.borderColor = Colors.orange.cgColor
        }) { _ in
            UIView.animate(withDuration: Constants.colorDuration) {
                field.layer.borderColor = originalColor
            }
        }
    }
    
    private func bindDynamicCheck() {
        let validator = SignupDataValidator()
        let nicknamePublisher = nameTextField.textPublisher
        let usernamePublisher = usernameTextField.textPublisher
        
        let isNameInputValid = nicknamePublisher
            .map { validator.validateName($0) }
        
        let isUsernameInputValid = usernamePublisher
            .map { validator.validateUsername($0) }
        
        let isUsernameAvailable = usernamePublisher
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .flatMap { username in
                
                self.activityIndicator.startAnimating()
                self.usernameIndicator.isHidden = true
                
                return Future<Bool, Error> { promise in
                    self.interactor.checkUsernameAvailability(username) { result in
                        promise(result)
                    }
                }
                .catch { _ in Just(false) }
                .handleEvents(receiveCompletion: { _ in
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.usernameIndicator.isHidden = false
                    }
                })
                .prepend(false)
            }
            .eraseToAnyPublisher()
        
        isNameInputValid
            .sink { [weak self] isValid in
                self?.updateNameUI(isValid: isValid)
            }
            .store(in: &cancellables)
        isUsernameInputValid
            .sink { [weak self] isValid in
                self?.updateUsernameUI(isValid: isValid)
            }.store(in: &cancellables)
        
        Publishers.CombineLatest(isUsernameInputValid, isUsernameAvailable)
            .sink { [weak self] (isFormatValid, isAvailable) in
                let isValid = isFormatValid && !isAvailable
                DispatchQueue.main.async {
                    self?.updateUsernameUI(isValid: isValid)
                }
            }
            .store(in: &cancellables)
        Publishers.CombineLatest3(isNameInputValid, isUsernameInputValid, isUsernameAvailable)
            .map { $0 && $1 && !$2 }
            .sink { [weak self] isEnabled in
                DispatchQueue.main.async {
                    self?.sendGradientButton.isEnabled = isEnabled
                    self?.sendGradientButton.alpha = isEnabled ? 1 : 0.5
                }
            }
            .store(in: &cancellables)
//        Publishers.CombineLatest(isNameInputValid, isUsernameInputValid)
//            .sink { [weak self] (isNameValid, isUsernameValid) in
//                let isEnabled = isNameValid && isUsernameValid
//                DispatchQueue.main.async {
//                    self?.sendGradientButton.isEnabled = isEnabled
//                    self?.sendGradientButton.alpha = isEnabled ? 1 : 0.5
//                }
//            }.store(in: &cancellables)
    }

    // MARK: - UI Helpers
    private func updateNameUI(isValid: Bool) {
        nameIndicator.image = isValid
            ? UIImage(systemName: "checkmark.circle.fill")
            : UIImage(systemName: "xmark.circle.fill")
        
        nameTextField.layer.borderColor = isValid
            ? UIColor.systemGreen.cgColor
            : UIColor.systemRed.cgColor
        
        nameIndicator.tintColor = isValid
            ? .systemGreen
            : .systemRed
    }

    private func updateUsernameUI(isValid: Bool) {
        usernameIndicator.image = isValid
            ? UIImage(systemName: "checkmark.circle.fill")
            : UIImage(systemName: "xmark.circle.fill")
        
        usernameTextField.layer.borderColor = isValid
            ? UIColor.systemGreen.cgColor
            : UIColor.systemRed.cgColor
        
        usernameIndicator.tintColor = isValid
            ? .systemGreen
            : .systemRed
    }
    
    // MARK: - Actions
    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc
    private func sendButtonPressed() {
        UIView.animate(withDuration: UIConstants.animationDuration, animations: {
            self.sendGradientButton.transform = CGAffineTransform(scaleX: UIConstants.buttonScale, y: UIConstants.buttonScale)
            }, completion: { _ in
            UIView.animate(withDuration: UIConstants.animationDuration) {
                self.sendGradientButton.transform = CGAffineTransform.identity
            }
        })
        
        guard let name = nameTextField.text, !name.isEmpty,
              let username = usernameTextField.text, !username.isEmpty else {
            return
        }
        interactor.sendSignupRequest(name, username)
    }
    
    @objc
    func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        let keyboardHeight = keyboardFrame.height

        // Raise view's elements if the keyboard overlaps the create account button.
        if let buttonFrame = sendGradientButton.superview?.convert(sendGradientButton.frame, to: nil) {
            let bottomY = buttonFrame.maxY
            let screenHeight = UIScreen.main.bounds.height
    
            if bottomY > screenHeight - keyboardHeight {
                let overlap = bottomY - (screenHeight - keyboardHeight)
                self.view.frame.origin.y -= overlap + Constants.extraKeyboardIndent
            }
        }
    }

    @objc
    func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @objc
    private func languageDidChange() {
        nameTextField.placeholder = LocalizationManager.shared.localizedString(for: "name")
        usernameTextField.placeholder = LocalizationManager.shared.localizedString(for: "username")
        sendGradientButton.setTitle(LocalizationManager.shared.localizedString(for: "create_account"))
    }
}

// MARK: - UITextFieldDelegate
extension SignupViewController: UITextFieldDelegate {}

extension UITextField {
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: self)
            .map { ($0.object as? UITextField)?.text ?? ""}
            .eraseToAnyPublisher()
    }
}
