//
//  NewMessageViewController.swift
//  chakchat
//
//  Created by лизо4ка курунок on 24.02.2025.
//

import UIKit

// MARK: - NewMessageViewController
final class NewMessageViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let arrowLabel: String = "arrow.left"
        static let newGroupButtonStartTop: CGFloat = -10
        static let newGroupButtonEndTop: CGFloat = 0
        static let newGroupButtonHorizontal: CGFloat = 10
        static let newGroupButtonHeight: CGFloat = 50
    }
    
    // MARK: - Properties
    private let interactor: NewMessageBusinessLogic
    private let titleLabel: UILabel = UILabel()
    private var searchController: UISearchController = UISearchController()
    private let newGroupButton: UINewGroupButton = UINewGroupButton()
    private let tableView: UITableView = UITableView()
    private var newGroupButtonTopConstraint: NSLayoutConstraint = NSLayoutConstraint()
    private var shouldAnimateNewGroupButton = false
    
    // MARK: - Initialization
    init(interactor: NewMessageBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    // MARK: - Add animation to NewGroupButton
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if shouldAnimateNewGroupButton {
            if searchController.isActive {
                animateNewGroupButton(constant: Constants.newGroupButtonEndTop)
            } else {
                animateNewGroupButton(constant: Constants.newGroupButtonStartTop)
            }
        }
        shouldAnimateNewGroupButton = false
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.background
        configureBackButton()
        configureTitleLabel()
        navigationItem.titleView = titleLabel
        configureSearchController()
        configureNewGroupButton()
    }
    
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.arrowLabel), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.text
        // Adding returning to previous screen with swipe.
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    private func configureTitleLabel() {
        view.addSubview(titleLabel)
        titleLabel.font = Fonts.systemB20
        titleLabel.text = LocalizationManager.shared.localizedString(for: "new_message")
        titleLabel.textAlignment = .center
    }
    
    private func configureSearchController() {
        let searchResultsController = UIUsersSearchViewController(interactor: interactor)
        searchResultsController.onUserSelected = { [weak self] user in
            self?.handleSelectedUser(user)
        }
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        searchController.searchBar.placeholder = LocalizationManager.shared.localizedString(for: "search")
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.setValue(LocalizationManager.shared.localizedString(for: "cancel"), forKey: "cancelButtonText")
        definesPresentationContext = true
    }
    
    private func configureNewGroupButton() {
        view.addSubview(newGroupButton)
        newGroupButton.pinLeft(view, Constants.newGroupButtonHorizontal)
        newGroupButton.pinRight(view, Constants.newGroupButtonHorizontal)
        newGroupButtonTopConstraint = newGroupButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.newGroupButtonStartTop)
        newGroupButtonTopConstraint.isActive = true
        newGroupButton.setHeight(Constants.newGroupButtonHeight)
        newGroupButton.addTarget(self, action: #selector(newGroupButtonPressed), for: .touchUpInside)
    }
    
    // MARK: - Supporting Methods
    private func animateNewGroupButton(constant: CGFloat) {
        UIView.animate(withDuration: 0.3) {
            self.newGroupButtonTopConstraint.constant = constant
            self.view.layoutIfNeeded()
        }
    }
    
    private func handleSelectedUser(_ userData: ProfileSettingsModels.ProfileUserData) {
        interactor.searchForExistingChat(userData)
    }
    
    // MARK: - Actions
    @objc
    private func backButtonPressed() {
        interactor.backToChatsScreen()
    }
    
    @objc
    private func newGroupButtonPressed() {
        interactor.newGroupRoute()
    }
}

// MARK: - UISearchResultsUpdating
extension NewMessageViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchVC = searchController.searchResultsController as? UIUsersSearchViewController else { return }
        if let searchText = searchController.searchBar.text {
            searchVC.searchTextPublisher.send(searchText)
        }
    }
}

// MARK: - UISearchControllerDelegate
extension NewMessageViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        shouldAnimateNewGroupButton = true
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        shouldAnimateNewGroupButton = true
    }
}
