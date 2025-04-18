//
//  ReactionView.swift
//  chakchat
//
//  Created by Кирилл Исаев on 18.04.2025.
//
import UIKit

class ReactionView: UIView {
    private let label = UILabel()
    var count: Int
    var isPicked = false
    private let reaction: String

    var onReactionChanged: ((String, Bool) -> Void)?
    var onRemove: (() -> Void)?

    init(reaction: String, count: Int = 1, isPicked: Bool = false) {
        self.reaction = reaction
        self.count = count
        self.isPicked = isPicked
        super.init(frame: .zero)
        configureCell()
        updateLabel()

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        self.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureCell() {
        backgroundColor = UIColor.white.withAlphaComponent(0.2)
        layer.cornerRadius = 14
        translatesAutoresizingMaskIntoConstraints = false

        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 40),
            heightAnchor.constraint(equalToConstant: 28),

            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        updateBackground()
    }

    private func updateLabel() {
        label.text = "\(reaction) \(count)"
        backgroundColor = isPicked ? UIColor.blue.withAlphaComponent(0.3) : UIColor.white.withAlphaComponent(0.2)
    }
    
    private func updateBackground() {
        if isPicked {
            backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        } else {
            backgroundColor = UIColor.systemGray4.withAlphaComponent(0.3)
        }
    }

    @objc private func didTap() {
        isPicked.toggle()
        count += isPicked ? 1 : -1
        updateLabel()
        onReactionChanged?(reaction, isPicked)
        
        if count <= 0 {
            onRemove?()
        }
    }
}
