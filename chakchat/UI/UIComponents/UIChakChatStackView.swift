//
//  UIChakChatStackView.swift
//  chakchat
//
//  Created by Кирилл Исаев on 15.01.2025.
//

import Foundation
import UIKit

// MARK: - UICkakChatStackView
final class UIChakChatStackView: UIStackView {
    
    // MARK: - Properties
    private var chakLabel: UILabel = {
        let label = UILabel()
        label.text = UIConstants.chakLabelText
        label.font = UIConstants.chakchatFont
        label.textColor = Colors.chakchat
        label.textAlignment = .center
        return label
    }()
    
    private var chatLabel: UILabel = {
        let label = UILabel()
        label.text = UIConstants.chatLabelText
        label.font = UIConstants.chakchatFont
        label.textColor = Colors.chakchat
        label.textAlignment = .center
        return label
    }()
    
    private lazy var chakchatStackView: UIStackView = {
        var stackView = UIStackView(arrangedSubviews: [chakLabel, chatLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = UIConstants.chakchatStackViewSpacing
        return stackView
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        addArrangedSubview(chakchatStackView)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
