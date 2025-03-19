//
//  UICustomTextField.swift
//  chakchat
//
//  Created by лизо4ка курунок on 01.02.2025.
//

import UIKit

// MARK: - UIProfileTextField
final class UIProfileTextField : UIView {
    
    // MARK: - Constants
    private enum Constants {
        static let titleTop: CGFloat = 7
        static let textTop: CGFloat = 2
        static let leading: CGFloat = 20
        static let trailing: CGFloat = 20
        static let lineBottom: CGFloat = 0
        static let lineTop: CGFloat = 9
        static let lineHeight: CGFloat = 0.5
        static let paddingX: CGFloat = 0
        static let paddingY: CGFloat = 0
        static let paddingWidth: CGFloat = 40
    }
    
    // MARK: - Properties
    private let titleLabel: UILabel = UILabel()
    public let textField: UITextField = UITextField()
    private let bottomLine: UIView = UIView()
    private var title: String = ""
    private var placeholder: String = ""
    
    // MARK: - Initialization
    init(title: String, placeholder: String, isEditable: Bool) {
        super.init(frame: .zero)
        configureUI(title: title, placeholder: placeholder, isEditable: isEditable)
        self.title = title
        self.placeholder = placeholder
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    func setText(_ text: String?) {
        textField.text = text
    }
    
    func getText() -> String? {
        return textField.text
    }
    
    func localize() {
        titleLabel.text = LocalizationManager.shared.localizedString(for: title)
        textField.placeholder = LocalizationManager.shared.localizedString(for: placeholder)
    }
    
    // MARK: - UI Configuration
    private func configureUI(title: String, placeholder: String, isEditable: Bool) {
        configureTitleLabel(title: title)
        configureTextField(placeholder: placeholder, isEditable: isEditable)
        configureBottomLine()
    }
    
    private func configureTitleLabel(title: String) {
        addSubview(titleLabel)
        titleLabel.text = LocalizationManager.shared.localizedString(for: title)
        titleLabel.font = Fonts.systemL14
        titleLabel.pinTop(self.topAnchor, Constants.titleTop)
        titleLabel.pinLeft(self.leadingAnchor, Constants.leading)
        titleLabel.textColor = UIColor.lightGray
    }
    
    private func configureTextField(placeholder: String, isEditable: Bool) {
        addSubview(textField)
        textField.pinTop(titleLabel.bottomAnchor, Constants.textTop)
        textField.pinLeft(self.leadingAnchor, Constants.leading)
        textField.pinRight(self.trailingAnchor, Constants.trailing)
        textField.placeholder = LocalizationManager.shared.localizedString(for: placeholder)
        textField.font = Fonts.systemM17
        textField.isUserInteractionEnabled = isEditable
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .none
        
        let rightPaddingView = UIView(
            frame: CGRect(
                x: Constants.paddingX,
                y: Constants.paddingY,
                width: Constants.paddingWidth,
                height: textField.frame.height
            )
        )
        textField.rightView = rightPaddingView
        textField.rightViewMode = .always
    }
    
    private func configureBottomLine() {
        addSubview(bottomLine)
        bottomLine.pinLeft(self.leadingAnchor, Constants.leading)
        bottomLine.pinRight(self.trailingAnchor, Constants.trailing)
        bottomLine.pinTop(textField.bottomAnchor, Constants.lineTop)
        bottomLine.pinBottom(self.bottomAnchor, Constants.lineBottom)
        
        bottomLine.setHeight(Constants.lineHeight)
        bottomLine.backgroundColor = UIColor.lightGray
    }
}
