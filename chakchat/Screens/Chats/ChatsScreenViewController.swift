//
//  ChatsScreenViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 21.01.2025.
//

import UIKit

// MARK: - ChatsScreenViewController
final class ChatsScreenViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let cancelButtonTitle: String = LocalizationManager.shared.localizedString(for: "cancel")
        static let cancelKey: String = "cancelButton"
        static let searchPlaceholder: String = LocalizationManager.shared.localizedString(for: "search")
        static let headerText: String = LocalizationManager.shared.localizedString(for: "chats")
        
        static let symbolSize: CGFloat = 25
        static let settingsName: String = "gearshape"
        static let plusName: String = "plus"
        static let chatsTableStartTop: CGFloat = -10
        static let chatsTableEndTop: CGFloat = 0
    }
    
    // MARK: - Properties
    private var titleLabel: UILabel = UILabel()
    private var settingButton: UIButton = UIButton(type: .system)
    private var newChatButton: UIButton = UIButton(type: .system)
    private let chatsTableView: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private var chatsData: [ChatsModels.GeneralChatModel.ChatData]? = []
    private lazy var searchController: UISearchController = UISearchController()
    private let interactor: ChatsScreenBusinessLogic
    private var chatsTableTopConstraint: NSLayoutConstraint = NSLayoutConstraint()
    private var shouldAnimateChatsTableView = false
    
    // MARK: - Lifecycle
    init(interactor: ChatsScreenBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.interactor.loadMeData()
        self.interactor.loadMeRestrictions()
        self.interactor.loadChats()
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: .languageDidChange, object: nil)
        configureUI()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if shouldAnimateChatsTableView {
            if searchController.isActive {
                animateChatsTableView(constant: Constants.chatsTableEndTop)
            } else {
                animateChatsTableView(constant: Constants.chatsTableStartTop)
            }
        }
        shouldAnimateChatsTableView = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            chatsTableView.reloadData()
        }
    }
    
    // MARK: - Public Methods
    func showChats(_ allChatsData: ChatsModels.GeneralChatModel.ChatsData) {
        chatsData = allChatsData.chats
        chatsTableView.reloadData()
    }
    
    func addNewChat(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        chatsData?.append(chatData)
        chatsTableView.reloadData()
    }
    
    func deleteChat(_ chatID: UUID) {
        if let i = chatsData?.firstIndex(where: {$0.chatID == chatID}) {
            chatsData?.remove(at: i)
            chatsTableView.reloadData()
        }
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.background
        configureTitleLabel()
        configureSettingsButton()
        configureNewChatButton()
        configureSearchController()
        configureChatsTableView()
    }
    
    private func configureTitleLabel() {
        view.addSubview(titleLabel)
        titleLabel.font = Fonts.systemB20
        titleLabel.text = Constants.headerText
        navigationItem.titleView = titleLabel
    }
    
    private func configureSearchController() {
        let searchResultsController = UIUsersSearchViewController(interactor: interactor)
        searchResultsController.onUserSelected = { [weak self] user in
            self?.handleUserPicked(user)
        }
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        searchController.searchBar.placeholder = Constants.searchPlaceholder
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.setValue(LocalizationManager.shared.localizedString(for: "cancel"), forKey: "cancelButtonText")
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func configureSettingsButton() {
        view.addSubview(settingButton)
        let config = UIImage.SymbolConfiguration(pointSize: Constants.symbolSize, weight: .light, scale: .default)
        let gearImage = UIImage(systemName: Constants.settingsName, withConfiguration: config)
        settingButton.tintColor = .gray
        settingButton.setImage(gearImage, for: .normal)
        settingButton.contentHorizontalAlignment = .fill
        settingButton.contentVerticalAlignment = .fill
        settingButton.addTarget(self, action: #selector(settingButtonPressed), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: settingButton)
    }
    
    private func configureNewChatButton() {
        view.addSubview(newChatButton)
        let config = UIImage.SymbolConfiguration(pointSize: Constants.symbolSize, weight: .light, scale: .default)
        let gearImage = UIImage(systemName: Constants.plusName, withConfiguration: config)
        newChatButton.tintColor = .gray
        newChatButton.setImage(gearImage, for: .normal)
        newChatButton.contentHorizontalAlignment = .fill
        newChatButton.contentVerticalAlignment = .fill
        newChatButton.addTarget(self, action: #selector(plusButtonPressed), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: newChatButton)
    }
    
    private func configureChatsTableView() {
        view.addSubview(chatsTableView)
        chatsTableTopConstraint = chatsTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.chatsTableStartTop)
        chatsTableTopConstraint.isActive = true
        chatsTableView.pinHorizontal(view)
        chatsTableView.pinBottom(view.bottomAnchor, 0)
        chatsTableView.backgroundColor = Colors.background
        chatsTableView.separatorInset = .zero
        chatsTableView.delegate = self
        chatsTableView.dataSource = self
        chatsTableView.register(ChatCell.self, forCellReuseIdentifier: "ChatCell")
    }
    
    private func handleUserPicked(_ user: ProfileSettingsModels.ProfileUserData) {
        interactor.searchForExistingChat(user)
    }
    
    private func animateChatsTableView(constant: CGFloat) {
        UIView.animate(withDuration: 0.3) {
            self.chatsTableTopConstraint.constant = constant
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Actions
    @objc
    private func settingButtonPressed() {
        interactor.routeToSettingsScreen()
    }
    
    @objc
    private func plusButtonPressed() {
        interactor.routeToNewMessageScreen()
    }
    
    @objc
    private func languageDidChange() {
        titleLabel.text = LocalizationManager.shared.localizedString(for: "chats")
        titleLabel.sizeToFit()
        searchController.searchBar.placeholder = LocalizationManager.shared.localizedString(for: "search")
        searchController.searchBar.setValue(LocalizationManager.shared.localizedString(for: "cancel"), forKey: "cancelButtonText")
    }
}

// MARK: - UISearchResultsUpdating
extension ChatsScreenViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchVC = searchController.searchResultsController as? UIUsersSearchViewController else { return }
        if let searchText = searchController.searchBar.text {
            searchVC.searchTextPublisher.send(searchText)
        }
    }
    func willPresentSearchController(_ searchController: UISearchController) {
        shouldAnimateChatsTableView = true
    }
    func willDismissSearchController(_ searchController: UISearchController) {
        shouldAnimateChatsTableView = true
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ChatsScreenViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let chatsData {
            return chatsData.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil 
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as? ChatCell else {
            return UITableViewCell()
        }
        if let item = chatsData?[indexPath.row] {
            interactor.getChatInfo(item) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let chatInfo):
                        cell.configure(chatInfo.chatPhotoURL, chatInfo.chatName)
                        cell.backgroundColor = .clear
                        cell.selectionStyle = .none
                    case .failure(let failure):
                        self.interactor.handleError(failure)
                    }
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let chatData = chatsData?[indexPath.row] else { return }
        interactor.routeToChat(chatData)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
