//
//  AddUserViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 24.03.2025.
//

import UIKit
import Combine

final class AddUserViewController: UIViewController {
    
    private var searchController: UISearchController = UISearchController()
    private let selectedUsersTable: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchResultsTable: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private var selectedUsers: [ProfileSettingsModels.ProfileUserData] = []
    private var coreDataUsers: [ProfileSettingsModels.ProfileUserData] = []
    private var fetchedUsers: [ProfileSettingsModels.ProfileUserData]?
    
    private let searchTextPublisher = PassthroughSubject<String, Never>()
    private var isLoading = false
    private var currentPage = 1
    private let limit = 10
    private let arrowLabel: String = "arrow.left"
    private var lastQuery: String?
    private var cancellable = Set<AnyCancellable>()
    
    var onUsersSelected: (([ProfileSettingsModels.ProfileUserData]) -> Void)?
    
    let interactor: AddUserBusinessLogic
    
    init(interactor: AddUserBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.backgroundSettings
        configureUI()
    }
    
    private func configureUI() {
        configureBackButton()
        configureSearchController()
        configureSelectedUsersTable()
        configureSearchResultsTable()
        configureWithCoreData()
        configureWithSelectedUsers()
        bindSearch()
    }
    
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: arrowLabel), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.text
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    private func configureWithCoreData() {
        interactor.loadCoreDataUsers() { [weak self] result in
            DispatchQueue.main.async {
                guard let result else { return }
                self?.coreDataUsers = result
                self?.searchResultsTable.reloadData()
            }
        }
    }
    
    private func configureWithSelectedUsers() {
        interactor.loadSelectedUsers() { [weak self] result in
            DispatchQueue.main.async {
                guard let result else { return }
                self?.selectedUsers = result
                self?.selectedUsersTable.reloadData()
            }
        }
    }
    
    private func configureSearchController() {
        searchController = UISearchController()
        searchController.delegate = self
        navigationItem.searchController = searchController
        searchController.searchBar.placeholder = LocalizationManager.shared.localizedString(for: "who_would_you_add")
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.setValue(LocalizationManager.shared.localizedString(for: "cancel"), forKey: "cancelButtonText")
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
    }
    
    private func configureSelectedUsersTable() {
        view.addSubview(selectedUsersTable)
        selectedUsersTable.backgroundColor = Colors.backgroundSettings
        selectedUsersTable.delegate = self
        selectedUsersTable.dataSource = self
        selectedUsersTable.pinTop(view.safeAreaLayoutGuide.topAnchor, 0)
        selectedUsersTable.pinHorizontal(view)
        selectedUsersTable.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, 0)
        selectedUsersTable.register(UISearchControllerCell.self, forCellReuseIdentifier: "SelectedUserCell")
    }
    
    private func configureSearchResultsTable() {
        view.addSubview(searchResultsTable)
        searchResultsTable.backgroundColor = Colors.backgroundSettings
        searchResultsTable.delegate = self
        searchResultsTable.dataSource = self
        searchResultsTable.pinTop(view.safeAreaLayoutGuide.topAnchor, 0)
        searchResultsTable.pinHorizontal(view)
        searchResultsTable.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, 0)
        searchResultsTable.register(UISearchControllerCell.self, forCellReuseIdentifier: "SearchResultCell")
        searchResultsTable.isHidden = true
    }
    
    private func handleSelectedUser(_ user: ProfileSettingsModels.ProfileUserData) {
        print("handle selection")
        let isAlreadySelected = selectedUsers.contains { $0.id == user.id }
        
        if !isAlreadySelected {
            selectedUsers.insert(user, at: 0)
            
            selectedUsersTable.performBatchUpdates {
                selectedUsersTable.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            }
            self.selectedUsersTable.reloadData()
        }
        if searchController.isActive {
            searchController.isActive = false
        }
    }
    
    private func bindSearch() {
        searchTextPublisher
            .removeDuplicates()
            .sink { [weak self] query in
                self?.startNewSearch(query)
            }.store(in: &cancellable)
    }
    
    private func startNewSearch(_ query: String) {
        fetchedUsers = []
        searchResultsTable.reloadData()
        guard !query.isEmpty else {
            return
        }
        currentPage = 1
        lastQuery = query
        fetchUsers(query, currentPage)
    }
    
    private func fetchUsers(_ query: String, _ page: Int) {
        guard !isLoading else { return }
        isLoading = true
        let isUsername = query.hasPrefix("@")
        let name = isUsername ? nil : query
        let username = isUsername ? String(query.dropFirst()) : nil
        
        interactor.fetchUsers(name, username, page, limit) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.fetchedUsers = response.users.filter { user in
                    user.name.localizedStandardContains(query) ||
                    user.username.localizedStandardContains(query)
                }
                DispatchQueue.main.async {
                    self.searchResultsTable.reloadData()
                }
            case .failure(let failure):
                self.interactor.handleError(failure)
            }
        }
    }
    
    @objc
    private func backButtonPressed() {
        onUsersSelected?(selectedUsers)
        navigationController?.popViewController(animated: true)
    }
}

extension AddUserViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == selectedUsersTable {
            return selectedUsers.count
        } else {
            if let fetchedUsers = fetchedUsers, !fetchedUsers.isEmpty {
                return fetchedUsers.count
            } else {
                return coreDataUsers.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == selectedUsersTable {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SelectedUserCell", for: indexPath) as? UISearchControllerCell else {
                return UITableViewCell()
            }
            let user = selectedUsers[indexPath.row]
            cell.configure(user.photo, user.name, deletable: false)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as? UISearchControllerCell else {
                return UITableViewCell()
            }
            let item: ProfileSettingsModels.ProfileUserData
            if let fetchedUsers = fetchedUsers, !fetchedUsers.isEmpty {
                item = fetchedUsers[indexPath.row]
                cell.configure(item.photo, item.name, deletable: false)
            } else {
                item = coreDataUsers[indexPath.row]
                cell.configure(item.photo, item.name, deletable: false)
            }
            return cell
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if tableView == selectedUsersTable {
            print("tap to cell")
        } else {
            if let fetchedUsers = fetchedUsers, !fetchedUsers.isEmpty {
                let user = fetchedUsers[indexPath.row]
                handleSelectedUser(user)
            } else {
                let user = coreDataUsers[indexPath.row]
                handleSelectedUser(user)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if tableView == selectedUsersTable {
            let deleteAction = UIContextualAction(style: .destructive, title: "_") { [weak self] (_, _, completion) in
                guard let self = self else { return }
                
                self.selectedUsers.remove(at: indexPath.row)
                
                tableView.performBatchUpdates({
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }, completion: { _ in
                    completion(true)
                })
            }
            deleteAction.backgroundColor = .systemRed
            deleteAction.image = UIImage(systemName: "trash")
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
        return nil
    }
}

extension AddUserViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    func willPresentSearchController(_ searchController: UISearchController) {
        searchResultsTable.isHidden = false
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        searchResultsTable.isHidden = true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            searchTextPublisher.send(searchText)
        }
    }
}
