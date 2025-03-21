//
//  UIImage+Letters.swift
//  chakchat
//
//  Created by лизо4ка курунок on 25.02.2025.
//

import UIKit

// MARK: - UIImage+Letters
/// Contains static funcs to create imageView with initials of text (parametr)
extension UIImage {
    
    static func imageWithText(
        text: String,
        size: CGSize,
        color: UIColor,
        borderWidth: CGFloat
    ) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            
            color.setFill()
            path.fill()
            
            color.setStroke()
            path.lineWidth = borderWidth
            path.stroke()
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.height / 2, weight: .bold),
                .foregroundColor: Colors.background
            ]
            
            let initials = getInitials(from: text)
            let textSize = initials.size(withAttributes: attributes)
            
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            initials.draw(in: textRect, withAttributes: attributes)
        }
        
        return image
    }
    
    // MARK: - Getting Initials
    private static func getInitials(from text: String) -> String {
        let words = text.uppercased().components(separatedBy: " ")
        let initials = words.prefix(2).compactMap { $0.first }
        return String(initials)
    }
}
