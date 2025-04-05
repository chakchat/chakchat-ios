//
//  UIMessageInputView.swift
//  chakchat
//
//  Created by лизо4ка курунок on 08.03.2025.
//

import UIKit

// MARK: - MessageInputView
final class MessageInputView: UIView {
    
    // MARK: - Constants
    private enum Constants {
        static let radius: CGFloat = 18
        static let symbolName: String = "arrow.up.circle.fill"
        static let alphaF: CGFloat = 0
        static let alphaS: CGFloat = 1
        static let duration: CGFloat = 0.2
        static let textFieldLeading: CGFloat = 16
        static let textFieldVertical: CGFloat = 16
        static let textFieldTrailing: CGFloat = -8
        static let sendButtonTrailing: CGFloat = 8
        static let sendButtonSize: CGFloat = 40
    }
    
    // MARK: - Properties
    private let textField = UITextField()
    weak var interactor: SendingMessagesProtocol?
    private let sendButton = UIButton()
    var bottomConstraint: NSLayoutConstraint = NSLayoutConstraint()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        configureKeyboardObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        backgroundColor = UIColor(named: "MessageInputView") 
        layer.cornerRadius = Constants.radius
        
        configureSendButton()
        configureTextField()
    }
    
    private func configureSendButton() {
        sendButton.setImage(UIImage(systemName: Constants.symbolName), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.alpha = Constants.alphaF
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        addSubview(sendButton)
        
        sendButton.pinRight(trailingAnchor, Constants.sendButtonTrailing)
        sendButton.pinCenterY(centerYAnchor)
        sendButton.setWidth(Constants.sendButtonSize)
        sendButton.setHeight(Constants.sendButtonSize)
        sendButton.imageView?.setWidth(Constants.sendButtonSize)
        sendButton.imageView?.setHeight(Constants.sendButtonSize)
    }
    
    private func configureTextField() {
        textField.placeholder = LocalizationManager.shared.localizedString(for: "type_here")
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.autocapitalizationType = .none
        
        addSubview(textField)
        
        textField.pinLeft(leadingAnchor, Constants.textFieldLeading)
        textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: Constants.textFieldTrailing).isActive = true
        textField.pinTop(topAnchor, Constants.textFieldVertical)
        textField.pinBottom(bottomAnchor, Constants.textFieldVertical)
    }
    
    // MARK: - Keyboard Observers Configuration
    private func configureKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Actions
    @objc
    private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        let keyboardHeight = keyboardFrame.cgRectValue.height
        bottomConstraint.constant = -keyboardHeight
        
        UIView.animate(withDuration: duration) {
            self.superview?.layoutIfNeeded()
        }
    }
    
    @objc
    private func keyboardWillHide(notification: NSNotification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        bottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.superview?.layoutIfNeeded()
        }
    }
    
    @objc
    private func textFieldDidChange() {
        let hasText = !(textField.text?.isEmpty ?? true)
        if hasText {
            UIView.animate(withDuration: Constants.duration) {
                self.sendButton.alpha = Constants.alphaS
            }
            if #available(iOS 17.0, *) {
                sendButton.imageView?.addSymbolEffect(.appear)
            }
        } else {
            UIView.animate(withDuration: Constants.alphaF) {
                self.sendButton.alpha = Constants.alphaF
            }
        }
    }
    
    @objc
    private func sendMessage() {
        guard let text = textField.text, !text.isEmpty else { return }
        interactor?.sendTextMessage(text)
        textField.text = nil
        sendButton.alpha = Constants.alphaF
    }
}

// MARK: - UITextFieldDelegate
extension MessageInputView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.async {
            let newPosition = textField.endOfDocument
            textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
        }
        sendButton.alpha = textField.text?.isEmpty == false ? 1 : 0
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.clearsOnInsertion = false
        textField.clearsOnBeginEditing = false
        return true
    }
}

