//
//  VerifyViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 08.01.2025.
//

import Foundation
import UIKit

// MARK: - VerifyViewController
final class VerifyViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let inputHintLabelTopAnchor: CGFloat = 10
        static let backButtonName: String = "arrow.left"
        
        static let inputDescriptionNumberOfLines: Int = 2
        static let inputDescriptionTop: CGFloat = 10
        
        static let digitsStackViewSpacing: CGFloat = 10
        static let digitsStackViewHeight: CGFloat = 50
        static let digitsStackViewTop: CGFloat = 20
        static let digitsStackViewLeading: CGFloat = 40
        static let digitsStackViewTrailing: CGFloat = 40
        
        static let textFieldBorderWidth: CGFloat = 1
        static let textFieldCornerRadius: CGFloat = 15
        static let textFieldFont: CGFloat = 24
        
        static let alphaStart: CGFloat = 0
        static let alphaEnd: CGFloat = 1
        static let errorLabelFontSize: CGFloat = 18
        static let errorLabelTop: CGFloat = 10
        static let errorDuration: TimeInterval = 0.5
        static let errorMessageDuration: TimeInterval = 2
        static let numberOfLines: Int = 2
        static let maxWidth: CGFloat = 320
        
        static let timerLabelBottom: CGFloat = 50
        static let extraKeyboardIndent: CGFloat = 40
        
        static let resendButtonHeight: CGFloat = 48
        static let resendButtonWidth: CGFloat = 230
        static let resendButtonBigWidth: CGFloat = 280
        static let resendButtonShortCount: Int = 11
    }
    
    // MARK: - Properties
    private var interactor: VerifyBusinessLogic
    private var textFields: [UITextField] = []
    private var inputDescriptionText: String = LocalizationManager.shared.localizedString(for: "we_sent_code")
    private var countdownTimer: Timer?
    private var timeLabelText: String = LocalizationManager.shared.localizedString(for: "resend_code_in")
    
    private var remainingTime: TimeInterval = 0
    private var rawPhone: String = ""
    private var formattedPhone: String = ""
    private var chakchatStackView: UIChakChatStackView = UIChakChatStackView()
    private var inputHintLabel: UILabel = UILabel()
    private var inputDescriptionLabel: UILabel = UILabel()
    private var digitsStackView: UIStackView = UIStackView()
    private var timerLabel: UILabel = UILabel()
    private var errorLabel: UIErrorLabel = UIErrorLabel(width: Constants.maxWidth, numberOfLines: Constants.numberOfLines)
    private var resendButton: UIGradientButton = UIGradientButton(title: LocalizationManager.shared.localizedString(for: "resend_code"))
    
    let timerDuration: TimeInterval = 90.0
    
    // MARK: - Lifecycle
    init(interactor: VerifyBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.background
        
        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: .languageDidChange, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        configureUI()
    }
    
    // MARK: - ViewWillAppear Overriding
    // Subscribing to Keyboard Notifications
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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

    // MARK: - Public methods
    func showPhone(_ phone: String) {
        guard let prettyPhone = Format.number(phone) else {
            return
        }
        formattedPhone = prettyPhone
        inputDescriptionText += formattedPhone
        rawPhone = phone
    }
    
    // TODO: локализировать ошибки
    func showError(_ message: String?) {
        if message != nil {
            errorLabel.showError(message)
            if message == "Incorrect code" {
                incorrectCode()
            }
        }
    }
    
    func hideResendButton() {
        resendButton.isHidden = true
        timerLabel.isHidden = false
        timerLabel.alpha = 1.0
        timerLabel.text = timeLabelText + "\n\(formatTime(Int(timerDuration)))"
        remainingTime = timerDuration
        startCountdown()
    }
    
    // MARK: - Incorrect Code Handling Method
    private func incorrectCode() {
        for i in 0..<textFields.count {
            if textFields.indices.contains(i), let thirdTextField = textFields[i] as? UIDeletableTextField {
                thirdTextField.shakeAndChangeColor()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            for i in 0..<self.textFields.count {
                self.textFields[i].text = ""
            }
            if let firstTextField = self.textFields.first {
                firstTextField.becomeFirstResponder()
            }
        }
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        configureBackButton()
        configureChakChatStackView()
        configureInputHintLabel()
        interactor.getPhone()
        configureInputDescriptionLabel()
        configureDigitsStackView()
        configureErrorLabel()
        configureTimerLabel()
        configureResendButton()
    }
    
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.backButtonName), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.text
        // Adding returning to previous screen with swipe.
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    private func configureChakChatStackView() {
        view.addSubview(chakchatStackView)
        chakchatStackView.pinCenterX(view)
        chakchatStackView.pinTop(view.safeAreaLayoutGuide.topAnchor, UIConstants.chakchatStackViewTopAnchor)
    }
    
    private func configureInputHintLabel() {
        view.addSubview(inputHintLabel)
        inputHintLabel.text = LocalizationManager.shared.localizedString(for: "enter_the_code")
        inputHintLabel.font = Fonts.systemB30
        inputHintLabel.pinCenterX(view)
        inputHintLabel.pinTop(chakchatStackView.bottomAnchor, Constants.inputHintLabelTopAnchor)
    }
  
    private func configureInputDescriptionLabel() {
        view.addSubview(inputDescriptionLabel)
        inputDescriptionLabel.textAlignment = .center
        inputDescriptionLabel.numberOfLines = Constants.inputDescriptionNumberOfLines
        inputDescriptionLabel.textColor = .gray
        inputDescriptionLabel.text = inputDescriptionText
        inputDescriptionLabel.pinCenterX(view)
        inputDescriptionLabel.pinTop(inputHintLabel.bottomAnchor, Constants.inputDescriptionTop)
    }
    
    private func configureDigitsStackView() {
        view.addSubview(digitsStackView)
        digitsStackView.axis = .horizontal
        digitsStackView.distribution = .fillEqually
        digitsStackView.spacing = Constants.digitsStackViewSpacing
        
        for i in 0..<6 {
            let textField = UIDeletableTextField()
            textField.layer.borderWidth = Constants.textFieldBorderWidth
            textField.layer.borderColor = UIColor.gray.cgColor
            textField.layer.cornerRadius = Constants.textFieldCornerRadius
            textField.textAlignment = .center
            textField.font = UIFont.systemFont(ofSize: Constants.textFieldFont)
            textField.keyboardType = .numberPad
            textField.delegate = self
            textField.tag = i
            digitsStackView.addArrangedSubview(textField)
            textFields.append(textField)
        }
        
        digitsStackView.setHeight(Constants.digitsStackViewHeight)
        digitsStackView.pinTop(inputDescriptionLabel.bottomAnchor, Constants.digitsStackViewTop)
        digitsStackView.pinCenterX(view)
        digitsStackView.pinLeft(view.leadingAnchor, Constants.digitsStackViewLeading)
        digitsStackView.pinRight(view.trailingAnchor, Constants.digitsStackViewTrailing)
    }
    
    private func configureErrorLabel() {
        view.addSubview(errorLabel)
        errorLabel.pinCenterX(view)
        errorLabel.pinTop(digitsStackView.bottomAnchor, Constants.errorLabelTop)
    }

    private func configureTimerLabel() {
        view.addSubview(timerLabel)
        timerLabel.pinCenterX(view)
        timerLabel.pinBottom(view, Constants.timerLabelBottom)
        timerLabel.textAlignment = .center
        timerLabel.textColor = .lightGray
        timerLabel.numberOfLines = 2
        timerLabel.text = timeLabelText + "\n\(formatTime(Int(timerDuration)))"
        remainingTime = timerDuration
        startCountdown()
    }
    
    private func configureResendButton() {
        view.addSubview(resendButton)
        resendButton.pinCenterX(view)
        resendButton.pinBottom(view, Constants.timerLabelBottom)
        resendButton.setHeight(Constants.resendButtonHeight)
        guard let label = resendButton.titleLabel,
              let text = label.text else {
            return
        }
        // If in title more than 11 chars, make button bigger.
        resendButton.setWidth(text.count > Constants.resendButtonShortCount
                                    ? Constants.resendButtonBigWidth
                                    : Constants.resendButtonWidth)
        resendButton.titleLabel?.font = Fonts.systemB25
        resendButton.addTarget(self, action: #selector(resendButtonPressed), for: .touchUpInside)
        resendButton.isHidden = true
    }
    
    // MARK: - Supporting Methods
    private func getCodeFromTextFields() -> String {
        var code: String = ""
        
        for field in textFields {
            guard let text = field.text, !text.isEmpty else {
                print("Empty text field found")
                return code
            }
            code.append(text)
        }
        print(code)
        return code
    }
    
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateLabel), userInfo: nil, repeats: true)
    }
    
    // MARK: - Actions
    @objc
    private func backButtonPressed() {
        interactor.routeToSendCodeScreen(SignupState.sendPhoneCode)
    }
    
    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc
    func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        let keyboardHeight = keyboardFrame.height

        // Raise view's elements if the keyboard overlaps the error label.
        // Check the overlap through digits stack view, because usually the error label is hidden.
        if let digitsFrame = digitsStackView.superview?.convert(digitsStackView.frame, to: nil) {
            let bottomY = digitsFrame.maxY
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
    func updateLabel() {
        remainingTime -= 1
        if remainingTime > 0 {
            timerLabel.text = timeLabelText + "\n\(formatTime(Int(remainingTime)))"
        } else {
            countdownTimer?.invalidate()
            hideLabel()
        }
    }

    @objc
    func hideLabel() {
        UIView.animate(withDuration: 0.5, animations: {
            self.timerLabel.alpha = 0.0
        }) { _ in
            self.timerLabel.isHidden = true
        }
        resendButton.isHidden = false
    }
    
    @objc
    private func resendButtonPressed() {
        UIView.animate(withDuration: UIConstants.animationDuration, animations: {
            self.resendButton.transform = CGAffineTransform(scaleX: UIConstants.buttonScale, y: UIConstants.buttonScale)
            }, completion: { _ in
            UIView.animate(withDuration: UIConstants.animationDuration) {
                self.resendButton.transform = CGAffineTransform.identity
            }
        })
        interactor.resendCodeRequest(
            VerifyModels.ResendCodeRequest(
                phone: rawPhone)
        )
    }
    
    @objc
    private func languageDidChange() {
        inputHintLabel.text = LocalizationManager.shared.localizedString(for: "enter_the_code")
        inputDescriptionText = LocalizationManager.shared.localizedString(for: "we_sent_code") + formattedPhone
        resendButton.setTitle(LocalizationManager.shared.localizedString(for: "resend_code"))
        guard let label = resendButton.titleLabel,
              let text = label.text else {
            return
        }
        // If in title more than 11 chars, make button bigger.
        resendButton.setWidth(text.count > Constants.resendButtonShortCount
                                    ? Constants.resendButtonBigWidth
                                    : Constants.resendButtonWidth)
        timeLabelText = LocalizationManager.shared.localizedString(for: "resend_code_in")
    }
}

// MARK: - UITextFieldDelegate Extension
extension VerifyViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if !isOnlyDigitsInString(string)
            { return false }
        
        if string.count > 1 {
            pasteString(string)
            return false
        }
        
        if !isInputDigitsOrDeleting(textField, string) {
            return false
        }
        
        if string.isEmpty {
            handleDelete(textField)
        } else {
            handleInput(textField, string)
        }
        
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectedTextRange = textField.textRange(from: textField.endOfDocument, to: textField.endOfDocument)
    }
    
    private func pasteString(_ string: String) {
        
        for field in textFields {
            field.text = ""
        }
        
        putOneCharacterInOneField(string)
        setLastTextFieldAsResponder(string)
        
        if areAllTextFieldsFilled() {
            sendRequestToInteractor()
        }
    }
    
    private func handleDelete(_ textField: UITextField) {
        if textField.tag > 0 {
            clearCell(textField.tag)
            setPreviousTextFieldAsResponder(textField)
        } else if textField.tag == 0 {
            clearCell(textField.tag)
        }
    }
    
    private func isInputDigitsOrDeleting(_ textField: UITextField, _ string: String) -> Bool {
        guard let _ = textField.text, string.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil || string.isEmpty else {
            return false
        }
        return true
    }
    
    private func handleInput(_ textField: UITextField, _ string: String) {
        textField.text = string
        
        moveToNextTextField(textField)
        
        if areAllTextFieldsFilled() {
            sendRequestToInteractor()
        }
    }
    
    private func moveToNextTextField(_ textField: UITextField) {
        let nextTag = textField.tag + 1
        if nextTag < textFields.count {
            textFields[nextTag].becomeFirstResponder()
        }
    }
    
    private func clearCell(_ textFieldTag: Int) {
        textFields[textFieldTag].text = ""
    }
    
    private func setPreviousTextFieldAsResponder(_ textField: UITextField) {
        let prevTag = textField.tag - 1
        textFields[prevTag].becomeFirstResponder()
    }
    
    private func isOnlyDigitsInString(_ string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        
        if !allowedCharacters.isSuperset(of: characterSet) {
            return false
        }
        return true
    }
    
    private func putOneCharacterInOneField(_ string: String) {
        for (index, char) in string.enumerated() {
            if index < textFields.count {
                textFields[index].text = String(char)
            }
        }
    }
    
    private func areAllTextFieldsFilled() -> Bool {
        for field in textFields {
            if field.text?.isEmpty == true {
                return false
            }
        }
        return true
    }
    
    private func setLastTextFieldAsResponder(_ string: String) {
        if string.count <= textFields.count {
            textFields[string.count - 1].becomeFirstResponder()
        } else {
            textFields.last?.becomeFirstResponder()
        }
    }
    
    private func sendRequestToInteractor() {
        let code = getCodeFromTextFields()
        interactor.sendVerificationRequest(code)
    }
}

