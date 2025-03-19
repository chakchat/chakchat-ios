//
//  UIGradientButton.swift
//  chakchat
//
//  Created by Кирилл Исаев on 15.01.2025.
//

import Foundation
import UIKit

// MARK: - UIGradientButton
final class UIGradientButton: UIButton {
    
    // MARK: - Properties
    private var buttonGradientLayer: CAGradientLayer? = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = UIConstants.gradientButtonGradientColor
        gradientLayer.startPoint = UIConstants.gradientButtonGradientStartPoint
        gradientLayer.endPoint = UIConstants.gradientButtonGradientEndPoint
        gradientLayer.cornerRadius = UIConstants.gradientButtonGradientCornerRadius
        return gradientLayer
    }()
    
    // MARK: - Initialization
    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(Colors.background, for: .normal)
        layer.cornerRadius = UIConstants.gradientButtonGradientCornerRadius
        
        if let gradientLayer = buttonGradientLayer {
            layer.insertSublayer(gradientLayer, at: 0)
        }
        
        isUserInteractionEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        buttonGradientLayer?.frame = bounds
    }
    
    func setTitle(_ title: String) {
        setTitle(title, for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
