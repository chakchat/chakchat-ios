//
//  UserProfileViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import UIKit

// MARK: - UserProfileViewController
final class UserProfileViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let configSize: CGFloat = 80
        static let borderWidth: CGFloat = 5
        static let cornerRadius: CGFloat = 50
        static let imageViewSize: CGFloat = 100
        static let imageViewTop: CGFloat = 10
        static let nicknameTop: CGFloat = 10
        static let arrowName: String = "arrow.left"
        static let borderRadius: CGFloat = 10
        static let buttonStackView: CGFloat = 10
        static let buttonWidth: CGFloat = 230
        static let buttonHeigth: CGFloat = 50
        static let buttonTop: CGFloat = 25
        static let userTableHorizontal: CGFloat = -15
        static let userTableBottom: CGFloat = 20
        static let userTableTop: CGFloat = 10
        static let userTableEstimateRow: CGFloat = 60
    }
    
    // MARK: - Properties
    private let interactor: UserProfileBusinessLogic
    private let iconImageView: UIImageView = UIImageView()
    private let config = UIImage.SymbolConfiguration(pointSize: Constants.configSize, weight: .light, scale: .default)
    private let nicknameLabel: UILabel = UILabel()
    private let buttonStackView: UIStackView = UIStackView()
    private let userDataTable: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private var userTableViewData: [(title: String, value: String)] = [
        (LocalizationManager.shared.localizedString(for: "username"), ""),
        (LocalizationManager.shared.localizedString(for: "phone"), ""),
        (LocalizationManager.shared.localizedString(for: "date_of_birth"), "")
    ]
    
    // MARK: - Initialization
    init(interactor: UserProfileBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        interactor.passUserData()
    }
    
    // MARK: - Changing image color
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            let color = UIColor.random()
            let image = UIImage.imageWithText(
                text: nicknameLabel.text ?? "",
                size: CGSize(width: Constants.configSize, height: Constants.configSize),
                backgroundColor: Colors.backgroundSettings,
                textColor: color,
                borderColor: color,
                borderWidth: Constants.borderWidth
            )
            iconImageView.image = image
        }
    }
    
    // MARK: - Public Methods
    func configureWithUserData(
        _ userData: ProfileSettingsModels.ProfileUserData,
        _ profileConfiguration: ProfileConfiguration
    ) {
        let color = UIColor.random()
        let image = UIImage.imageWithText(
            text: userData.name,
            size: CGSize(width: Constants.configSize, height: Constants.configSize),
            backgroundColor: Colors.backgroundSettings,
            textColor: color,
            borderColor: color,
            borderWidth: Constants.borderWidth
        )
        iconImageView.image = image
        if let photoURL = userData.photo {
            iconImageView.image = ImageCacheManager.shared.getImage(for: photoURL as NSURL)
            iconImageView.layer.cornerRadius = Constants.cornerRadius
        }
        nicknameLabel.text = userData.name
        userTableViewData[0].value = userData.username
        userTableViewData[1].value = Format.number(userData.phone) ?? ""
        if let birth = userData.dateOfBirth {
            userTableViewData[2].value = birth
        }
        switch (profileConfiguration.isSecret, profileConfiguration.fromGroupChat) {
        case (true, true):
            let chatButton = createButton("message.fill",
                                          LocalizationManager.shared.localizedString(for: "chat_l"))
            chatButton.addTarget(self, action: #selector(chatButtonPressed), for: .touchUpInside)
            buttonStackView.addArrangedSubview(chatButton)
            buttonStackView.setWidth(310)
        case (true, false):
            break
        case (false, true):
            let chatButton = createButton("message.fill",
                                          LocalizationManager.shared.localizedString(for: "chat_l"))
            chatButton.addTarget(self, action: #selector(chatButtonPressed), for: .touchUpInside)
            let secretChatButton = createButton("key.fill",
                                                LocalizationManager.shared.localizedString(for: "secret_chat_l"))
            buttonStackView.addArrangedSubview(chatButton)
            buttonStackView.addArrangedSubview(secretChatButton)
            buttonStackView.setWidth(390)
        case (false, false):
            let secretChatButton = createButton("key.fill",
                                                LocalizationManager.shared.localizedString(for: "secret_chat_l"))
            buttonStackView.addArrangedSubview(secretChatButton)
            buttonStackView.setWidth(310)
        }
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.backgroundSettings

        configureBackButton()
        configureIconImageView()
        configureInitials()
        configureButtonStackView()
        configureUserDataTable()
    }
    
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.arrowName), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.text
        
        // Adding returning to previous screen with swipe.
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    private func configureIconImageView() {
        view.addSubview(iconImageView)
        iconImageView.setHeight(Constants.imageViewSize)
        iconImageView.setWidth(Constants.imageViewSize)
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.layer.cornerRadius = Constants.cornerRadius
        iconImageView.layer.masksToBounds = true
        iconImageView.pinCenterX(view)
        iconImageView.pinTop(view.safeAreaLayoutGuide.topAnchor, Constants.imageViewTop)
        let gearImage = UIImage(systemName: "camera.circle", withConfiguration: config)
        iconImageView.tintColor = Colors.lightOrange
        iconImageView.image = gearImage
    }
    
    private func configureInitials() {
        view.addSubview(nicknameLabel)
        nicknameLabel.font = Fonts.systemSB20
        nicknameLabel.textColor = Colors.text
        nicknameLabel.pinTop(iconImageView.bottomAnchor, Constants.nicknameTop)
        nicknameLabel.pinCenterX(view)
    }
    
    private func configureButtonStackView() {
        view.addSubview(buttonStackView)
        
        let notificationButton = createButton("bell.badge.fill",
                                              LocalizationManager.shared.localizedString(for: "sound_l"))
        let searchButton = createButton("magnifyingglass",
                                        LocalizationManager.shared.localizedString(for: "search_l"))
        let optionsButton = createButton("ellipsis",
                                         LocalizationManager.shared.localizedString(for: "more_l"))
        
        buttonStackView.addArrangedSubview(notificationButton)
        buttonStackView.addArrangedSubview(searchButton)
        buttonStackView.addArrangedSubview(optionsButton)
        
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = Constants.buttonStackView
        buttonStackView.setWidth(Constants.buttonWidth)
        buttonStackView.setHeight(Constants.buttonHeigth)
        buttonStackView.pinTop(nicknameLabel.bottomAnchor, Constants.buttonTop)
        buttonStackView.pinCenterX(view)
        
        let blockAction = UIAction(title: LocalizationManager.shared.localizedString(for: "block_chat"), image: UIImage(systemName: "lock.fill")) { _ in
            self.showBlockConfirmation()
        }
        let deleteAction = UIAction(title: LocalizationManager.shared.localizedString(for: "delete_chat"), image: UIImage(systemName: "trash.fill"), attributes: .destructive) { _ in
            self.showBlockDeletion()
        }
        let menu = UIMenu(title: LocalizationManager.shared.localizedString(for: "choose_option"), children: [blockAction, deleteAction])
        optionsButton.menu = menu
        optionsButton.showsMenuAsPrimaryAction = true
    }
    
    private func createButton(_ systemName: String, _ title: String) -> UIButton {
        let button = UIUserProfileButton()
        button.configure(withSymbol: systemName, title: title)
        button.backgroundColor = Colors.userButtons
        button.tintColor = .orange
        button.setTitleColor(.orange, for: .normal)
        button.layer.cornerRadius = Constants.borderRadius
        return button
    }
    
    private func showBlockConfirmation() {
        let alert = UIAlertController(title: LocalizationManager.shared.localizedString(for: "block_chat"), message: LocalizationManager.shared.localizedString(for: "are_you_sure_block"), preferredStyle: .alert)
  
        let blockAction = UIAlertAction(title: LocalizationManager.shared.localizedString(for: "block_chat"), style: .destructive) { _ in
            self.blockChat()
        }
        let cancelAction = UIAlertAction(title: LocalizationManager.shared.localizedString(for: "cancel"), style: .cancel, handler: nil)
        
        alert.addAction(blockAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showBlockDeletion() {
        let alert = UIAlertController(title: LocalizationManager.shared.localizedString(for: "delete_chat"), message: LocalizationManager.shared.localizedString(for: "for_whom"), preferredStyle: .alert)
  
        let onlyMeAction = UIAlertAction(title: LocalizationManager.shared.localizedString(for: "delete_for_me"), style: .default) { _ in
            self.deleteChatForMe()
        }
        let bothAction = UIAlertAction(title: LocalizationManager.shared.localizedString(for: "delete_for_both"), style: .destructive) { _ in
            self.deleteCharForBoth()
        }
        let cancelAction = UIAlertAction(title: LocalizationManager.shared.localizedString(for: "cancel"), style: .cancel, handler: nil)
        
        alert.addAction(onlyMeAction)
        alert.addAction(bothAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func configureUserDataTable() {
        view.addSubview(userDataTable)
        userDataTable.delegate = self
        userDataTable.dataSource = self
        userDataTable.separatorStyle = .singleLine
        userDataTable.separatorInset = .zero
        userDataTable.isUserInteractionEnabled = false
        userDataTable.pinHorizontal(view, Constants.userTableHorizontal)
        userDataTable.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, Constants.userTableBottom)
        userDataTable.pinTop(buttonStackView.bottomAnchor, Constants.userTableTop)
        userDataTable.register(UserProfileCell.self, forCellReuseIdentifier: UserProfileCell.cellIdentifier)
        userDataTable.backgroundColor = view.backgroundColor
        userDataTable.rowHeight = UITableView.automaticDimension
        userDataTable.estimatedRowHeight = Constants.userTableEstimateRow
    }
    
    // MARK: - Interactor methods
    private func blockChat() {
        interactor.blockChat()
    }
    
    private func deleteChatForMe() {
        interactor.deleteChat(DeleteMode.onlyMe)
    }
    
    private func deleteCharForBoth() {
        interactor.deleteChat(DeleteMode.all)
    }
    
    @objc private func chatButtonPressed() {
        interactor.searchForExistingChat()
    }
    
    @objc private func secretChatButtonPressed() {
        
    }
    
    @objc private func backButtonPressed() {
        interactor.routeBack()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension UserProfileViewController: UITableViewDelegate, UITableViewDataSource {
    // if user dont pick his date of birth he/she will see only 3 sections in current screen
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userTableViewData[2].value == "" ? 2 : 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserProfileCell.cellIdentifier, for: indexPath) as? UserProfileCell else {
            return UITableViewCell()
        }
        let item = userTableViewData[indexPath.row]
        
        // if it's phone number -> formatting
        if item.title == "Phone", let formattedPhone = Format.number(item.value) {
            cell.configure(with: item.title, value: formattedPhone)
        } else {
            cell.configure(with: item.title, value: item.value)
        }
        
        return cell
    }
}
