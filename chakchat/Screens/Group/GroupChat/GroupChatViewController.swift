//
//  GroupChatViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit

final class GroupChatViewController: UIViewController {
    
    // MARK: - Constants
    enum Constants {
        static let navigationItemHeight: CGFloat = 44
        static let borderWidth: CGFloat = 5
        static let cornerRadius: CGFloat = 22
        static let spacing: CGFloat = 12
        static let arrowName: String = "arrow.left"
        static let messageInputViewHorizontal: CGFloat = 8
        static let messageInputViewHeigth: CGFloat = 50
        static let messageInputViewBottom: CGFloat = 0
    }
    
    // MARK: - Properties
    private let interactor: GroupChatBusinessLogic
    private let messageInputView = MessageInputView()
    private let iconImageView: UIImageView = UIImageView()
    private let groupNameLabel: UILabel = UILabel()
    private var tapGesture: UITapGestureRecognizer?
    private let newChatAlert: UINewChatAlert = UINewChatAlert()
    
    // MARK: - Initialization
    init(interactor: GroupChatBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        interactor.passChatData()
    }
    
    func configureWithData(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        if case .group(let groupInfo) = chatData.info {
            let color = UIColor.random()
            let image = UIImage.imageWithText(
                text: groupInfo.name,
                size: CGSize(width: Constants.navigationItemHeight, height:  Constants.navigationItemHeight),
                color: color,
                borderWidth: Constants.borderWidth
            )
            iconImageView.image = image
            if let photoURL = groupInfo.groupPhoto {
                iconImageView.image = ImageCacheManager.shared.getImage(for: photoURL as NSURL)
                iconImageView.layer.cornerRadius = Constants.cornerRadius
            }
            groupNameLabel.text = groupInfo.name
        }
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.background
        
        configureBackButton()
        configureIconImageView()
        configureNicknameLabel()
        configureMessageView()
        configureNewChatAlert()
    }
    
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.arrowName), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.text
        
        // Adding returning to previous screen with swipe.
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture?.delegate = self
        if let tapGesture = tapGesture {
            view.addGestureRecognizer(tapGesture)
        }
    }
    
    private func configureIconImageView() {
        view.addSubview(iconImageView)
        iconImageView.layer.cornerRadius = Constants.cornerRadius
        iconImageView.clipsToBounds = true
        iconImageView.setWidth(Constants.navigationItemHeight)
        iconImageView.setHeight(Constants.navigationItemHeight)
        addTapGesture(to: iconImageView)

        let barButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = barButtonItem
    }
    
    private func configureNicknameLabel() {
        view.addSubview(groupNameLabel)
        groupNameLabel.textAlignment = .center
        groupNameLabel.font = Fonts.systemSB20
        groupNameLabel.textColor = Colors.text
        navigationItem.titleView = groupNameLabel
        addTapGesture(to: groupNameLabel)
    }
    
    private func addTapGesture(to view: UIView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTitleTap))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
    }
    
    private func configureMessageView() {
        view.addSubview(messageInputView)
        messageInputView.interactor = interactor
        messageInputView.pinLeft(view.leadingAnchor, Constants.messageInputViewHorizontal)
        messageInputView.pinRight(view.trailingAnchor, Constants.messageInputViewHorizontal)
        messageInputView.setHeight(Constants.messageInputViewHeigth)
        messageInputView.bottomConstraint = messageInputView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: Constants.messageInputViewBottom
        )
        messageInputView.bottomConstraint.isActive = true
    }
    
    private func configureNewChatAlert() {
        newChatAlert.configure(title: LocalizationManager.shared.localizedString(for: "alert_group_title"),
                             message: LocalizationManager.shared.localizedString(for: "alert_group"))
        view.addSubview(newChatAlert)
        
        newChatAlert.pinCenterX(view)
        newChatAlert.pinCenterY(view)
        newChatAlert.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8).isActive = true
    }
    
    @objc private func handleTitleTap() {
        interactor.routeToChatProfile()
    }
    
    // MARK: - Actions
    @objc private func backButtonPressed() {
        interactor.routeBack()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension GroupChatViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint = touch.location(in: view)
        return !messageInputView.frame.contains(touchPoint)
    }
}
