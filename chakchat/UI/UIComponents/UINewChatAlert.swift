//
//  UINewChatAlert.swift
//  chakchat
//
//  Created by лизо4ка курунок on 21.03.2025.
//

import UIKit

final class UINewChatAlert: UIView {
    
    // MARK: - Constants
    private enum Constants {
        static let numbersOfLines: Int = 0
        static let spacing: CGFloat = 8
        static let alpha: CGFloat = 0.8
        static let cornerRadius: CGFloat = 12
        static let pin: CGFloat = 16
    }
    
    // MARK: - Properties
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.systemB18
        label.textColor = Colors.text
        label.textAlignment = .center
        label.numberOfLines = Constants.numbersOfLines
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = Fonts.systemR16
        label.textColor = Colors.text
        label.textAlignment = .left
        label.numberOfLines = Constants.numbersOfLines
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        stack.axis = .vertical
        stack.spacing = Constants.spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }
    
    // MARK: - Configuration
    func configure(title: String, message: String) {
        titleLabel.text = title
        messageLabel.text = message
    }
    
    // MARK: - Setup
    private func configureView() {
        backgroundColor = UIColor(named: "EmptyChatMessageColor") ?? .tertiaryLabel
        layer.cornerRadius = Constants.cornerRadius
        layer.masksToBounds = true
        
        addSubview(stackView)
        
        stackView.pinTop(self.topAnchor, Constants.pin)
        stackView.pinBottom(self.bottomAnchor, Constants.pin)
        stackView.pinLeft(self.leadingAnchor, Constants.pin)
        stackView.pinRight(self.trailingAnchor, Constants.pin)
    }
}
