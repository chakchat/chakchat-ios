//
//  RegistrationViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.01.2025.
//

import UIKit
import SafariServices

// MARK: - SendCodeViewController
final class SendCodeViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let inputNumberLabelFontSize: CGFloat = 16
        static let inputNumberLabelTopAnchor: CGFloat = 100
        
        static let inputNumberTextFieldTopAnchor: CGFloat = 50
        static let descriptionLabelBottom: CGFloat = 4
        static let linksTop: CGFloat = 4
        static let linksHorizontal: CGFloat = 20
        static let linksBottom: CGFloat = 40
        
        static let linkTermLocation: Int = 0
        
        static let policyStackViewSpacing: CGFloat = 5
        static let policyStackViewTopAnchor: CGFloat = 5
        
        static let inputButtonHeight: CGFloat = 48
        static let inputButtonWidth: CGFloat = 205
        static let inputButtonBigWidth: CGFloat = 235
        static let inputButtonShortCount: Int = 9
        
        static let disclaimerLeading: CGFloat = 20
        static let disclaimerTrailing: CGFloat = 20
        static let disclaimerBottom: CGFloat = 10
        
        static let disablingCharactersAmount: Int = 4
        static let numberKerning: CGFloat = 2
        
        static let shortNumberLabelTop: CGFloat = 360
        static let shortNumberDuration: TimeInterval = 0.5
        
        static let numberOfLines: Int = 2
        static let maxWidth: CGFloat = 330
        static let errorLabelTop: CGFloat = 0
        
        static let extraKeyboardIndent: CGFloat = 20
    }
    
    // MARK: - Properties
    private var interactor: SendCodeBusinessLogic
    private var chakchatStackView: UIChakChatStackView = UIChakChatStackView()
    private var inputNumberTextField: UIPhoneNumberTextField = UIPhoneNumberTextField()
    private var sendGradientButton: UIGradientButton = UIGradientButton(title: LocalizationManager.shared.localizedString(for: "send_code"))
    private var shortNumberLabel: UILabel = UILabel()
    private var descriptionLabel: UILabel = UILabel()
    private var termsLabel: UILabel = UILabel()
    private var errorLabel: UIErrorLabel = UIErrorLabel(width: Constants.maxWidth, numberOfLines: Constants.numberOfLines)
    private let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
    
    private var isPhoneNubmerInputValid: Bool = false
    
    // MARK: - Lifecycle
    init(interactor: SendCodeBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    // MARK: - ViewWillAppear Overriding
    // Subscribing to Keyboard Notifications
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: .languageDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - ViewWillDisappear Overriding
    // Unubscribing to Keyboard Notifications
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Show Error as label
    func showError(_ message: String?) {
        if message != nil {
            errorLabel.showError(message)
        }
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.background
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        self.navigationItem.hidesBackButton = true
        
        configureChakChatStackView()
        configureInputNumberTextField()
        configureInputButton()
        configureTermsView()
        configureCountinuingLabel()
        configurateErrorLabel()
    }
    
    private func configureChakChatStackView() {
        view.addSubview(chakchatStackView)
        chakchatStackView.pinTop(view.safeAreaLayoutGuide.topAnchor, UIConstants.chakchatStackViewTopAnchor)
        chakchatStackView.pinCenterX(view)
    }
    
    private func configureInputNumberTextField() {
        view.addSubview(inputNumberTextField)
        inputNumberTextField.pinTop(chakchatStackView.bottomAnchor, Constants.inputNumberTextFieldTopAnchor)
        inputNumberTextField.pinCenterX(view)
        inputNumberTextField.delegate = self
    }
    
    private func configureInputButton() {
        view.addSubview(sendGradientButton)
        sendGradientButton.pinCenterX(view)
        sendGradientButton.pinTop(inputNumberTextField.bottomAnchor, UIConstants.gradientButtonTopAnchor)
        sendGradientButton.setHeight(Constants.inputButtonHeight)
        guard let label = sendGradientButton.titleLabel,
              let text = label.text else {
            return
        }
        // If in title more than 9 chars, make button bigger.
        sendGradientButton.setWidth(text.count > Constants.inputButtonShortCount
                                    ? Constants.inputButtonBigWidth
                                    : Constants.inputButtonWidth)
        sendGradientButton.titleLabel?.font = Fonts.systemB25
        sendGradientButton.addTarget(self, action: #selector(sendButtonPressed), for: .touchUpInside)
    }
    
    private func configureCountinuingLabel() {
        view.addSubview(descriptionLabel)
        descriptionLabel.text = LocalizationManager.shared.localizedString(for: "agreement_with_prompt")
        descriptionLabel.textColor = Colors.text
        descriptionLabel.font = Fonts.systemR15
        descriptionLabel.pinBottom(termsLabel.topAnchor, Constants.descriptionLabelBottom)
        descriptionLabel.pinCenterX(view)
    }

    private func configureTermsView() {
        view.addSubview(termsLabel)
        let underlineAttributedString = NSAttributedString(string: "StringWithUnderLine", attributes: underlineAttribute)
        termsLabel.attributedText = underlineAttributedString
        termsLabel.text = LocalizationManager.shared.localizedString(for: "terms_of_service_label")
        termsLabel.font = Fonts.systemR12
        termsLabel.textColor = Colors.darkYellow
        termsLabel.isUserInteractionEnabled = true
        termsLabel.lineBreakMode = .byWordWrapping
        termsLabel.numberOfLines = 1
        termsLabel.pinCenterX(view)
        termsLabel.pinBottom(view, Constants.linksBottom)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openTerms))
        termsLabel.addGestureRecognizer(tapGesture)
    }
    
    private func configurateErrorLabel() {
        view.addSubview(errorLabel)
        errorLabel.pinCenterX(view)
        errorLabel.pinTop(chakchatStackView.bottomAnchor, Constants.errorLabelTop)
    }

    // MARK: - TextField Handling
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }
        
        switch(textField) {
        case inputNumberTextField:
            let validator = PhoneValidator()
            isPhoneNubmerInputValid = validator.validate(text)
        default:
            break
        }
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
        
        guard let phoneText = inputNumberTextField.text else {
            errorLabel.showError(LocalizationManager.shared.localizedString(for: "enter_valid_number"))
            return
        }
        
        let cleanedPhone = phoneText.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if isPhoneNubmerInputValid {
            interactor.routeToVerifyScreen(cleanedPhone)
        } else {
            errorLabel.showError(LocalizationManager.shared.localizedString(for: "enter_valid_number"))
        }
    }
    
    @objc
    func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        let keyboardHeight = keyboardFrame.height

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
    func openTerms() {
        if let url = URL(string: LocalizationManager.shared.localizedString(for: "terms_link_github")) {
            let safariVC = SFSafariViewController(url: url)
            safariVC.modalPresentationStyle = .formSheet
            present(safariVC, animated: true, completion: nil)
        }
    }
    
    @objc
    private func languageDidChange() {
        descriptionLabel.text = LocalizationManager.shared.localizedString(for: "agreement_with_prompt")
        termsLabel.text = LocalizationManager.shared.localizedString(for: "terms_of_service_label")
        sendGradientButton.setTitle(LocalizationManager.shared.localizedString(for: "send_code"))
        guard let label = sendGradientButton.titleLabel,
              let text = label.text else {
            return
        }
        // If in title more than 9 chars, make button bigger.
        sendGradientButton.setWidth(text.count > Constants.inputButtonShortCount
                                    ? Constants.inputButtonBigWidth
                                    : Constants.inputButtonWidth)
    }
}

// MARK: - UITextFieldDelegate
extension SendCodeViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let selectedRange = textField.selectedTextRange {
            let cursorOffset = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)

            if cursorOffset < 4 && selectedRange.isEmpty {
                if let newPosition = textField.position(from: textField.beginningOfDocument, offset: 4) {
                    textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                }
            }
        }
    }
}
