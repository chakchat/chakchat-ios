//
//  GroupChatProfileViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit

final class GroupChatProfileViewController: UIViewController {
    
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
        static let buttonWidth: CGFloat = 310
        static let buttonHeigth: CGFloat = 50
        static let buttonTop: CGFloat = 25
        static let userTableHorizontal: CGFloat = -15
        static let userTableBottom: CGFloat = 20
        static let userTableTop: CGFloat = 10
        static let userTableEstimateRow: CGFloat = 60
    }
    
    private enum Localization: String {
        case deleteGroup = "delete_group"
        case deleteMember = "delete_member"
        case deleteGroupDisclaimer = "are_you_sure_delete_group"
        case deleteMemberDisclaimer = "are_you_sure_delete_member"
    }
    
    // MARK: - Properties
    private let interactor: GroupChatProfileBusinessLogic
    private let iconImageView: UIImageView = UIImageView()
    private let config = UIImage.SymbolConfiguration(pointSize: Constants.configSize, weight: .light, scale: .default)
    private let groupNameLabel: UILabel = UILabel()
    private lazy var searchController: UISearchController = UISearchController()
    private let userDataTable: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private var userTableViewData: [ProfileSettingsModels.ProfileUserData] = []
    private let buttonStackView: UIStackView = UIStackView()
    
    // MARK: - Initialization
    init(interactor: GroupChatProfileBusinessLogic) {
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
    
    // MARK: - Changing image color
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            guard let text = groupNameLabel.text else { return }
            let image = UIProfilePhoto(text, Constants.imageViewSize, Constants.borderWidth).getPhoto()
            iconImageView.image = image
        }
    }
    
    // MARK: - User Data Configuration
    func configureWithUserData(_ chatData: ChatsModels.GeneralChatModel.ChatData, _ isAdmin: Bool) {
        if case .group(let groupInfo) = chatData.info {
            let color = UIColor.random()
            let image = UIImage.imageWithText(
                text: groupInfo.name,
                size: CGSize(width: Constants.configSize, height: Constants.configSize),
                backgroundColor: Colors.backgroundSettings,
                textColor: color,
                borderColor: color,
                borderWidth: Constants.borderWidth
            )
            iconImageView.image = image
            if let photoURL = groupInfo.groupPhoto {
                iconImageView.image = ImageCacheManager.shared.getImage(for: photoURL as NSURL)
                iconImageView.layer.cornerRadius = Constants.cornerRadius
            }
            groupNameLabel.text = groupInfo.name
        }
        if isAdmin {
            configureEditButton()
            let optionsButton = createButton("ellipsis",
                                             LocalizationManager.shared.localizedString(for: "more_l"))
            createMenu(optionsButton)
            buttonStackView.addArrangedSubview(optionsButton)
        } else {
            buttonStackView.setWidth(230)
        }
        
        interactor.getUserDataByID(chatData.members) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    self.userTableViewData.append(data)
                    self.userDataTable.reloadData()
                case .failure(let failure):
                    self.interactor.handleError(failure)
                }
            }
        }
    }
    
    func updateGroupInfo(_ name: String, _ description: String?) {
        groupNameLabel.text = name
    }
    
    func updateGroupPhoto(_ image: UIImage?) {
        if let image {
            iconImageView.image = image
        } else {
            let color = UIColor.random()
            guard let groupName = groupNameLabel.text else { return }
            let image = UIImage.imageWithText(
                text: groupName,
                size: CGSize(width: Constants.configSize, height: Constants.configSize),
                backgroundColor: Colors.backgroundSettings,
                textColor: color,
                borderColor: color,
                borderWidth: Constants.borderWidth
            )
            iconImageView.image = image
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
        configureSearchController()
        
    }
    
    // MARK: - Back Button Configuration
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.arrowName), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.text
        
        // Adding returning to previous screen with swipe.
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    private func configureEditButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: LocalizationManager.shared.localizedString(for: "edit"), style: .plain, target: self, action: #selector(editButtonPressed))
        navigationItem.rightBarButtonItem?.tintColor = Colors.lightOrange
    }
    
    // MARK: - Icon Image View Configuration
    private func configureIconImageView() {
        view.addSubview(iconImageView)
        iconImageView.setHeight(Constants.imageViewSize)
        iconImageView.setWidth(Constants.imageViewSize)
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.layer.cornerRadius = Constants.cornerRadius
        iconImageView.layer.masksToBounds = true
        iconImageView.pinCenterX(view)
        iconImageView.pinTop(view.safeAreaLayoutGuide.topAnchor, Constants.imageViewTop)
        iconImageView.tintColor = Colors.lightOrange
    }
    
    // MARK: - Initials Configuration
    private func configureInitials() {
        view.addSubview(groupNameLabel)
        groupNameLabel.font = Fonts.systemSB20
        groupNameLabel.textColor = Colors.text
        groupNameLabel.pinTop(iconImageView.bottomAnchor, Constants.nicknameTop)
        groupNameLabel.pinCenterX(view)
    }
    
    // MARK: - Button Stack View Configuration
    private func configureButtonStackView() {
        view.addSubview(buttonStackView)
        let notificationButton = createButton("bell.badge.fill",
                                              LocalizationManager.shared.localizedString(for: "sound_l"))
        let secretChatButton = createButton("key.fill",
                                            LocalizationManager.shared.localizedString(for: "secret_chat_l"))
        let searchButton = createButton("magnifyingglass",
                                        LocalizationManager.shared.localizedString(for: "search_l"))
        
        buttonStackView.addArrangedSubview(notificationButton)
        buttonStackView.addArrangedSubview(secretChatButton)
        buttonStackView.addArrangedSubview(searchButton)
        
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = Constants.buttonStackView
        buttonStackView.setWidth(Constants.buttonWidth)
        buttonStackView.setHeight(Constants.buttonHeigth)
        buttonStackView.pinTop(groupNameLabel.bottomAnchor, Constants.buttonTop)
        buttonStackView.pinCenterX(view)
    }
    
    private func configureUserDataTable() {
        view.addSubview(userDataTable)
        userDataTable.delegate = self
        userDataTable.dataSource = self
        userDataTable.separatorStyle = .singleLine
        userDataTable.separatorInset = .zero
        userDataTable.pinHorizontal(view, -15)
        userDataTable.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, 20)
        userDataTable.pinTop(buttonStackView.bottomAnchor, 10)
        userDataTable.register(UISearchControllerCell.self, forCellReuseIdentifier: UISearchControllerCell.cellIdentifier)
        userDataTable.backgroundColor = view.backgroundColor
        userDataTable.rowHeight = UITableView.automaticDimension
        userDataTable.estimatedRowHeight = 60
    }
    
    private func configureSearchController() {
        let searchResultsController = UIUsersSearchViewController(interactor: interactor)
        searchResultsController.onUserSelected = { [weak self] user in
            self?.handleSelectedUser(user)
        }
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = LocalizationManager.shared.localizedString(for: "who_would_you_add")
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.setValue(LocalizationManager.shared.localizedString(for: "cancel"), forKey: "cancelButtonText")
        definesPresentationContext = true
    }
    
    private func createMenu(_ optionsButton: UIButton) {
        let addMember = UIAction(title: LocalizationManager.shared.localizedString(for: "add_member"), image: UIImage(systemName: "person.crop.circle.fill.badge.plus")) { _ in
            self.addMember()
        }
        let deleteMember = UIAction(title: LocalizationManager.shared.localizedString(for: "delete_member"), image: UIImage(systemName: "person.crop.circle.fill.badge.minus"), attributes: .destructive) { _ in
            self.deleteMember()
        }
        let deleteGroup = UIAction(title: LocalizationManager.shared.localizedString(for: "delete_group"), image: UIImage(systemName: "trash.fill"), attributes: .destructive) { _ in
            self.showDisclaimer(Localization.deleteGroup.rawValue, Localization.deleteGroupDisclaimer.rawValue)
        }
        let menu = UIMenu(title: LocalizationManager.shared.localizedString(for: "choose_option"), children: [addMember, deleteMember, deleteGroup])
        optionsButton.menu = menu
        optionsButton.showsMenuAsPrimaryAction = true
    }
    /// параметры по умолчанию нужны для того чтобы в случае удаления участника
    /// я мог помнить о том какой у него UUID и какой индекс в таблице
    private func showDisclaimer(_ event: String, _ deleteWhat: String, _ memberID: UUID = UUID(), _ i: Int = 0) {
        let alert = UIAlertController(title: LocalizationManager.shared.localizedString(for: event), message: LocalizationManager.shared.localizedString(for: deleteWhat), preferredStyle: .alert)
        if event == Localization.deleteGroup.rawValue {
            let deleteAction = UIAlertAction(title: LocalizationManager.shared.localizedString(for: event), style: .destructive) { _ in
                self.deleteGroup()
            }
            alert.addAction(deleteAction)
        } else {
            let deleteAction = UIAlertAction(title: LocalizationManager.shared.localizedString(for: event), style: .destructive) { _ in
                self.handleMemberDeletion(memberID, i)
            }
            alert.addAction(deleteAction)
        }
        let cancelAction = UIAlertAction(title: LocalizationManager.shared.localizedString(for: "cancel"), style: .cancel) { _ in
        }
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
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
    
    private func handleSelectedUser(_ user: ProfileSettingsModels.ProfileUserData) {
        interactor.addMember(user.id)
    }
    
    private func addMember() {
        present(searchController, animated: true)
    }
    
    private func deleteMember() {
        for cell in userDataTable.visibleCells {
            if let indexPath = userDataTable.indexPath(for: cell) {
                let item = userTableViewData[indexPath.row]
                (cell as? UISearchControllerCell)?.configure(item.photo, item.name, deletable: true)
            }
        }
    }
    
    private func handleMemberDeletion(_ memberID: UUID, _ i: Int) {
        interactor.deleteMember(memberID)
        userTableViewData.remove(at: i)
        userDataTable.reloadData()
    }
    
    private func deleteGroup() {
        interactor.deleteGroup()
    }
    
    @objc private func editButtonPressed() {
        interactor.routeToEdit()
    }
    
    @objc private func backButtonPressed() {
        interactor.routeBack()
    }
}

extension GroupChatProfileViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchVC = searchController.searchResultsController as? UIUsersSearchViewController else { return }
        if let searchText = searchController.searchBar.text {
            searchVC.searchTextPublisher.send(searchText)
        }
    }
}

extension GroupChatProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userTableViewData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UISearchControllerCell.cellIdentifier, for: indexPath) as? UISearchControllerCell else {
            return UITableViewCell()
        }
        let item = userTableViewData[indexPath.row]
        cell.configure(item.photo, item.name, deletable: false)
        cell.deleteAction = nil
        cell.deleteAction = { [weak self] in
            self?.showDisclaimer(
                Localization.deleteMember.rawValue,
                Localization.deleteMemberDisclaimer.rawValue,
                item.id,
                indexPath.row
            )
        }
        return cell
    }
}

