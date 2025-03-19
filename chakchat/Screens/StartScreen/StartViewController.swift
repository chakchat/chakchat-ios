//
//  StartViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 07.01.2025.
//

import Foundation
import UIKit

// MARK: - StartViewController
final class StartViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let chakchatStackViewSpacing: CGFloat = -60
        static let tapLabelButtom: CGFloat = 50
        static let chakLabelText: String = "Chak"
        static let chatLabelText: String = "Chat"
        static let gradientLocation: [NSNumber] = [0.0, 0.5, 1.0]
        static let gradientStartPoint: CGPoint = CGPoint(x: 0.5, y: 0.0)
        static let gradientEndPoint: CGPoint = CGPoint(x: 0.5, y: 1.0)
        static let gradientSublayerAt: UInt32 = 0
    }
    
    // MARK: - Properties
    private var startMessengerButton: UIButton = UIButton(type: .system)
    private var chakLabel: UILabel = UILabel()
    private var chatLabel: UILabel = UILabel()
    private var tapLabel: UILabel = UILabel()
    private lazy var chakchatStackView = UIStackView(arrangedSubviews: [chakLabel, chatLabel])
    private var gradientBackgroundLayer: CAGradientLayer = CAGradientLayer()
    var onRouteToSendCodeScreen: ((SignupState) -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        configureGradientBackgroundLayer()
        configureStartMessengerLabel()
        configureTapLabel()
    }
    
    private func configureGradientBackgroundLayer() {
        gradientBackgroundLayer.colors = [
            Colors.orange.cgColor,
            Colors.yellow.cgColor,
            Colors.orange.cgColor
        ]
        gradientBackgroundLayer.locations = Constants.gradientLocation
        gradientBackgroundLayer.startPoint = Constants.gradientStartPoint
        gradientBackgroundLayer.endPoint = Constants.gradientEndPoint
        gradientBackgroundLayer.frame = view.bounds
        view.layer.insertSublayer(gradientBackgroundLayer, at: Constants.gradientSublayerAt)
    }
    
    private func configureStartMessengerLabel() {
        view.addSubview(chakLabel)
        view.addSubview(chatLabel)
        chakLabel.text = Constants.chakLabelText
        chakLabel.textAlignment = .center
        chakLabel.font = Fonts.rammettoOneR100
        chakLabel.textColor = .black
        
        chatLabel.text = Constants.chatLabelText
        chatLabel.textAlignment = .center
        chatLabel.font = Fonts.rammettoOneR100
        chatLabel.textColor = .black
        
        view.addSubview(chakchatStackView)
        chakchatStackView.axis = .vertical
        chakchatStackView.alignment = .center
        chakchatStackView.spacing = Constants.chakchatStackViewSpacing
        chakchatStackView.pinCenter(view)
    }
    
    private func configureTapLabel() {
        view.addSubview(tapLabel)
        tapLabel.text = LocalizationManager.shared.localizedString(for: "tap_hint")
        tapLabel.textAlignment = .center
        tapLabel.font = Fonts.montserratB25
        tapLabel.textColor = .black
        tapLabel.pinCenterX(view)
        tapLabel.pinBottom(view, Constants.tapLabelButtom)
    }
    
    // MARK: - Actions
    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
        onRouteToSendCodeScreen?(SignupState.sendPhoneCode)
    }
}
