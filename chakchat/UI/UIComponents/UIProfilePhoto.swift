//
//  UIProfilePhoto.swift
//  chakchat
//
//  Created by Кирилл Исаев on 18.03.2025.
//

import UIKit

final class UIProfilePhoto: UIView {
    
    private let image: UIImage
    
    init(_ text: String, _ size: CGFloat, _ borderWidth: CGFloat) {
        let color = UIColor.random()
        self.image = UIImage.imageWithText(
            text: LocalizationManager.shared.localizedString(for: text),
            size: CGSize(width: size, height: size),
            color: color,
            borderWidth: borderWidth
        ) ?? UIImage()
        super.init(frame: .zero)
    }
    
    func getPhoto() -> UIImage {
        return image
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
