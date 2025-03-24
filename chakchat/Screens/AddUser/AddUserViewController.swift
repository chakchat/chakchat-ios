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
    private let usersTable: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private var coreDataUsers: [ProfileSettingsModels.ProfileUserData] = []
    private var fetchedUsers: [ProfileSettingsModels.ProfileUserData]?
    private let searchTextPublisher = PassthroughSubject<String, Never>()
    private var isLoading = false
    private var currentPage = 1
    private let limit = 10
    private var lastQuery: String?
    private var cancellable = Set<AnyCancellable>()
    
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
        interactor.loadData()
    }
    
    public func configureWithData(_ users: [ProfileSettingsModels.ProfileUserData]) {
        coreDataUsers = users
        usersTable.reloadData()
    }
    
    private func configureUI() {
        configureSearchController()
        configureUsersTable()
        bindSearch()
    }
    
    private func configureSearchController() {
        let searchResultsController = UIUsersSearchViewController(interactor: interactor)
        searchResultsController.onUserSelected = { [weak self] user in
            self?.handleSelectedUser(user)
        }
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        navigationItem.searchController = searchController
        searchController.searchBar.placeholder = LocalizationManager.shared.localizedString(for: "who_would_you_add")
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.setValue(LocalizationManager.shared.localizedString(for: "cancel"), forKey: "cancelButtonText")
        definesPresentationContext = true
    }
    
    private func configureUsersTable() {
        view.addSubview(usersTable)
        usersTable.backgroundColor = Colors.backgroundSettings
        usersTable.delegate = self
        usersTable.dataSource = self
        usersTable.pinTop(view.safeAreaLayoutGuide.topAnchor, 0)
        usersTable.pinHorizontal(view)
        usersTable.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, 0)
        usersTable.register(UISearchControllerCell.self, forCellReuseIdentifier: UISearchControllerCell.cellIdentifier)
        
    }
    
    private func handleSelectedUser(_ user: ProfileSettingsModels.ProfileUserData) {
        fetchedUsers?.append(user)
        usersTable.reloadData()
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
        usersTable.reloadData()
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
            isLoading = false
            switch result {
            case .success(let response):
                self.fetchedUsers = response.users.filter { user in
                    user.name.localizedStandardContains(query) ||
                    user.username.localizedStandardContains(query)
                }
                DispatchQueue.main.async {
                    self.usersTable.reloadData()
                }
            case .failure(let failure):
                interactor.handleError(failure)
            }
        }
    }
}

extension AddUserViewController:  UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedUsers?.count ?? coreDataUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UISearchControllerCell.cellIdentifier, for: indexPath) as? UISearchControllerCell else {
            return UITableViewCell()
        }
        let item = fetchedUsers?[indexPath.row] ?? coreDataUsers[indexPath.row]
        cell.configure(item.photo, item.name, deletable: false)
        return cell
    }
}

extension AddUserViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchVC = searchController.searchResultsController as? UIUsersSearchViewController else { return }
        if let searchText = searchController.searchBar.text {
            searchVC.searchTextPublisher.send(searchText)
        }
    }
}
