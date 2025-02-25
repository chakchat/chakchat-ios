//
//  NewGroupViewController.swift
//  chakchat
//
//  Created by лизо4ка курунок on 25.02.2025.
//

import UIKit

// MARK: - NewGroupViewController
final class NewGroupViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let arrowLabel: String = "arrow.left"
        static let checkmarkLabel: String = "checkmark"
        static let emptyButtonStartTop: CGFloat = -10
        static let emptyButtonEndTop: CGFloat = 0
        static let tableTop: CGFloat = 10
        static let tableBottom: CGFloat = 0
        static let tableHorizontal: CGFloat = 0
        static let imageViewSize: CGFloat = 90
        static let imageBorderWidth: CGFloat = 10
    }
    
    // MARK: - Properties
    private let interactor: NewGroupBusinessLogic
    private let titleLabel: UINewGroupTitleLabel = UINewGroupTitleLabel()
    private var searchController: UISearchController = UISearchController()
    private var users: [ProfileSettingsModels.ProfileUserData] = []
    private var emptyButtonTopConstraint: NSLayoutConstraint!
    // Clear button. It needed cause there was a problem with pinning table top.
    private let emptyButton: UIButton = UIButton()
    private let tableView: UITableView = UITableView()
    private var shouldAnimateEmptyButton = false
    private let usersTableView: UITableView = UITableView()
    private var iconImageView: UIImageView = UIImageView()
    private let groupLabel: UILabel = UILabel()
    private let groupTextField: UITextField = UITextField()

    
    // MARK: - Initialization
    init(interactor: NewGroupBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if shouldAnimateEmptyButton {
            if searchController.isActive {
                animateEmptyButton(constant: Constants.emptyButtonEndTop)
            } else {
                animateEmptyButton(constant: Constants.emptyButtonStartTop)
            }
        }
        shouldAnimateEmptyButton = false
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.background
        configureBackButton()
        configureCreateButton()
        configureTitleLabel()
        configureSearchController()
        configureEmptyButton()
        configureIconImageView()
        configureGroupTextFiled()
        configureTableView()
    }
    
    // MARK: - Back Button Configuration
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.arrowLabel), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.orange
        // Adding returning to previous screen with swipe.
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    // MARK: - Create Button Configuration
    private func configureCreateButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.checkmarkLabel), style: .plain, target: self, action: #selector(createButtonPressed))
        navigationItem.rightBarButtonItem?.tintColor = Colors.orange
    }
    
    // MARK: - Title Label Configure
    private func configureTitleLabel() {
        view.addSubview(titleLabel)
        navigationItem.titleView = titleLabel
    }
    
    // MARK: - Search Controller Configuration
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
        searchController.searchBar.setValue(LocalizationManager.shared.localizedString(for: "cancel"), forKey: "cancelButtonText")
        definesPresentationContext = true
    }
    
    // MARK: - New Group Configuration
    private func configureEmptyButton() {
        view.addSubview(emptyButton)
        emptyButton.pinLeft(view, 10)
        emptyButton.pinRight(view, 10)
        emptyButtonTopConstraint = emptyButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -10)
        emptyButtonTopConstraint.isActive = true
        emptyButton.setHeight(0)
    }
    
    // MARK: - Table Configuration
    private func configureTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.pinTop(groupTextField.bottomAnchor, Constants.tableTop)
        tableView.pinBottom(view, Constants.tableBottom)
        tableView.pinLeft(view, Constants.tableHorizontal)
        tableView.pinRight(view, Constants.tableHorizontal)
        tableView.separatorInset = .zero
        tableView.register(UISearchControllerCell.self, forCellReuseIdentifier: "SearchControllerCell")
    }
    
    // MARK: - Icon ImageView Configuration
    private func configureIconImageView(title: String = "new_group") {
        let image = UIImage.imageWithText(
            text: LocalizationManager.shared.localizedString(for: title),
            size: CGSize(width: Constants.imageViewSize, height: Constants.imageViewSize),
            backgroundColor: Colors.background,
            textColor: Colors.lightOrange,
            borderColor: Colors.lightOrange,
            borderWidth: Constants.imageBorderWidth
        )
        
        iconImageView = UIImageView(image: image)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
        iconImageView.clipsToBounds = true
        view.addSubview(iconImageView)
        iconImageView.pinCenterX(view)
        iconImageView.pinTop(emptyButton.bottomAnchor, Constants.tableTop)
        
        iconImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(iconImageViewTapped))
        iconImageView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Group Text Field Configuration
    private func configureGroupTextFiled() {
        view.addSubview(groupTextField)
        groupTextField.pinTop(iconImageView.bottomAnchor, 10)
        groupTextField.pinCenterX(view.centerXAnchor)
        groupTextField.sizeToFit()
        groupTextField.placeholder = LocalizationManager.shared.localizedString(for: "group_name")
        groupTextField.font = Fonts.systemR18
        groupTextField.autocorrectionType = .no
        groupTextField.spellCheckingType = .no
        groupTextField.autocapitalizationType = .none
        groupTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        
        let underlineLayer = UIView()
        underlineLayer.setHeight(1)
        underlineLayer.backgroundColor = UIColor.systemGray5
        groupTextField.addSubview(underlineLayer)
        underlineLayer.pinBottom(groupTextField.bottomAnchor, 0)
        underlineLayer.pinLeft(groupTextField.leadingAnchor, 0)
        underlineLayer.pinRight(groupTextField.trailingAnchor, 0)
    }

    
    // MARK: - Updating iconImageView after picking pic
    private func addPickedImage(_ image: UIImage) {
        iconImageView.setHeight(Constants.imageViewSize)
        iconImageView.setWidth(Constants.imageViewSize)
        iconImageView.image = image
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
    }
    
    // MARK: - Empty Button Animation.
    // we pin empty button to end of navigation bar and animate it when user tap to searchBar.
    // tableView is pinned to emptyButton so it is animated too.
    private func animateEmptyButton(constant: CGFloat) {
        UIView.animate(withDuration: 0.3) {
            self.emptyButtonTopConstraint.constant = constant
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Handling user selected.
    private func handleSelectedUser(_ user: ProfileSettingsModels.ProfileUserData) {
        if users.contains(where: { $0.username == user.username }) {
            searchController.isActive = false
            return
        }
        users.append(user)
        titleLabel.updateCounter(users.count)
        tableView.reloadData()
        searchController.isActive = false
    }
    
    // MARK: - Actions
    @objc
    private func backButtonPressed() {
        interactor.backToNewMessageScreen()
    }
    
    @objc
    private func createButtonPressed() {
        // Creating group
    }
    
    @objc
    private func iconImageViewTapped() {
        // TODO: added screen with setting image
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc
    private func textFieldDidChange(_ textField: UITextField) {
        // updating textAligment
        DispatchQueue.main.async {
            let isEmpty = textField.text?.isEmpty == true
            textField.textAlignment = isEmpty ? .left : .center
            
            if isEmpty {
                textField.text = " "
                textField.text = ""
            }
        }
    }

}

// MARK: - UISearchResultsUpdating
extension NewGroupViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchVC = searchController.searchResultsController as? UIUsersSearchViewController else { return }
        if let searchText = searchController.searchBar.text {
            searchVC.searchTextPublisher.send(searchText)
        }
    }
}

// MARK: - UISearchControllerDelegate
extension NewGroupViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        shouldAnimateEmptyButton = true
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        shouldAnimateEmptyButton = true
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
// TODO: make pretty cells here and everywhere where searchBar is.
extension NewGroupViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchControllerCell", for: indexPath) as? UISearchControllerCell else {
            return UITableViewCell()
        }
        let user = users[indexPath.row]
        cell.configure(user.photo, user.name)
        return cell
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension NewGroupViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            addPickedImage(pickedImage)
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
