//
//  ChatBackgroundGradientView.swift
//  chakchat
//
//  Created by лизо4ка курунок on 05.04.2025.
//

import UIKit

final class ChatBackgroundGradientView: UIView {
    
    private let gradientLayer = CAGradientLayer()
    private var colors: [UIColor] = []
    
    init() {
        super.init(frame: .zero)
    }
    
    init(colors: [UIColor],
         startPoint: CGPoint = CGPoint(x: 0.5, y: 0.0),
         endPoint: CGPoint = CGPoint(x: 0.5, y: 1.0)) {
        self.colors = colors
        super.init(frame: .zero)
        configureGradient(startPoint: startPoint, endPoint: endPoint)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    func updateColors(_ newColors: [UIColor]) {
        colors = newColors
        gradientLayer.colors = newColors.map { $0.cgColor }
    }
    
    func updateDirection(startPoint: CGPoint, endPoint: CGPoint) {
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
    }
    
    private func configureGradient(startPoint: CGPoint, endPoint: CGPoint) {
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = calculateLocations(for: colors.count)
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func calculateLocations(for colorCount: Int) -> [NSNumber] {
        guard colorCount > 1 else { return [0.0, 1.0] }
        let step = 1.0 / Double(colorCount - 1)
        return (0..<colorCount).map { NSNumber(value: Double($0) * step) }
    }
}
