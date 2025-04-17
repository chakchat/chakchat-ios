//
//  NewGroupViewController.swift
//  chakchat
//
//  Created by лизо4ка курунок on 25.02.2025.
//

import UIKit
import CropViewController

// MARK: - NewGroupViewController
final class NewGroupViewController: UIViewController, CropViewControllerDelegate {
    
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
        static let groupTextFieldWidth: CGFloat = 400
        static let maxGroupNameLength: Int = 50
    }
    
    // MARK: - Properties
    private let interactor: NewGroupBusinessLogic
    private let titleLabel: UINewGroupTitleLabel = UINewGroupTitleLabel()
    private var searchController: UISearchController = UISearchController()
    private var users: [ProfileSettingsModels.ProfileUserData] = []
    private var emptyButtonTopConstraint: NSLayoutConstraint = NSLayoutConstraint()
    private let emptyButton: UIButton = UIButton()
    private let tableView: UITableView = UITableView()
    private var shouldAnimateEmptyButton = false
    private let usersTableView: UITableView = UITableView()
    private var iconImageView: UIImageView = UIImageView()
    private let groupLabel: UILabel = UILabel()
    private let groupTextField: UITextField = UITextField()
    private var groupTextFieldWidthConstraint: NSLayoutConstraint = NSLayoutConstraint()
    private var isImageSet: Bool = false
    private let clearButton: UIButton = UIButton(type: .system)
    private var photoMenu: UIMenu = UIMenu(children: [])
    private var isPhoto: Bool = false
    
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
        configureClearButtonOnImage()
        configureGroupTextFiled()
        configureTableView()
    }
    
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.arrowLabel), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.orange
        // Adding returning to previous screen with swipe.
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }

    private func configureCreateButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.checkmarkLabel), style: .plain, target: self, action: #selector(createButtonPressed))
        navigationItem.rightBarButtonItem?.tintColor = Colors.orange
    }
    
    private func configureTitleLabel() {
        view.addSubview(titleLabel)
        navigationItem.titleView = titleLabel
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
        searchController.searchBar.setValue(LocalizationManager.shared.localizedString(for: "cancel"), forKey: "cancelButtonText")
        definesPresentationContext = true
    }
    
    private func configureEmptyButton() {
        view.addSubview(emptyButton)
        emptyButton.pinLeft(view, 10)
        emptyButton.pinRight(view, 10)
        emptyButtonTopConstraint = emptyButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -10)
        emptyButtonTopConstraint.isActive = true
        emptyButton.setHeight(0)
    }
    
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
    
    private func configureIconImageView(title: String = "new_group") {
        let color = UIColor.random()
        let image = UIImage.imageWithText(
            text: LocalizationManager.shared.localizedString(for: title),
            size: CGSize(width: Constants.imageViewSize, height: Constants.imageViewSize),
            color: color,
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
    }
    
    private func configureGroupTextFiled() {
        view.addSubview(groupTextField)
        groupTextField.pinTop(iconImageView.bottomAnchor, 10)
        groupTextField.pinCenterX(view.centerXAnchor)
        groupTextField.delegate = self
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
        
        let placeholder = LocalizationManager.shared.localizedString(for: "group_name")
        let initialWidth = calculateWidth(for: placeholder)
        groupTextField.placeholder = placeholder
        groupTextFieldWidthConstraint = groupTextField.widthAnchor.constraint(equalToConstant: initialWidth)
        groupTextFieldWidthConstraint.isActive = true
    }
    
    private func configureClearButtonOnImage() {
        iconImageView.layoutIfNeeded()

        clearButton.frame = iconImageView.bounds
        clearButton.backgroundColor = .clear
        clearButton.layer.cornerRadius = iconImageView.layer.cornerRadius
        clearButton.layer.masksToBounds = true

        iconImageView.addSubview(clearButton)
        
        let editAction = UIAction(
            title: LocalizationManager.shared.localizedString(for: "edit"),
            image: UIImage(systemName: "pencil")
        ) { action in
            self.chooseImage()
        }
        photoMenu = UIMenu(children: [editAction])
        clearButton.menu = photoMenu
        clearButton.showsMenuAsPrimaryAction = true
    }

    
    // MARK: - Supporting Methods
    private func addPickedImage(_ image: UIImage) {
        iconImageView.setHeight(Constants.imageViewSize)
        iconImageView.setWidth(Constants.imageViewSize)
        iconImageView.image = image
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
        isImageSet = true
    }
    
    // we pin empty button to end of navigation bar and animate it when user tap to searchBar.
    // tableView is pinned to emptyButton so it is animated too.
    private func animateEmptyButton(constant: CGFloat) {
        UIView.animate(withDuration: 0.3) {
            self.emptyButtonTopConstraint.constant = constant
            self.view.layoutIfNeeded()
        }
    }

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
    
    private func updateTextFieldWidth(for text: String) {
        let placeholderText = LocalizationManager.shared.localizedString(for: "group_name")
        let calculatedWidth = max(calculateTextWidth(for: text), calculateTextWidth(for: placeholderText))
        let finalWidth = min(calculatedWidth, Constants.groupTextFieldWidth)
        
        groupTextFieldWidthConstraint.constant = finalWidth
        view.layoutIfNeeded()
    }
    
    private func chooseImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func sendDeleteImage() {
        guard iconImageView.image != nil else {
            return
        }
        configureIconImageView()
        configureClearButtonOnImage()
        isImageSet = false
    }
    
    // MARK: - Actions
    @objc
    private func backButtonPressed() {
        interactor.backToNewMessageScreen()
    }
    
    @objc
    private func createButtonPressed() {
        guard let name = groupTextField.text else {
            print("Type name for group!")
            return
        }
        let members = users.map { $0.id }
        interactor.createGroupChat(name, nil, members, isImageSet ? iconImageView.image : nil)
    }
    
    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc
    private func textFieldDidChange(_ textField: UITextField) {
        DispatchQueue.main.async {
            let isEmpty = textField.text?.isEmpty == true
            textField.textAlignment = isEmpty ? .left : .center
            
            if isEmpty {
                textField.text = " "
                textField.text = ""
            }
            
            self.updateTextFieldWidth(for: textField.text ?? "")
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
        cell.configure(user.photo, user.name, deletable: true)
        cell.selectionStyle = .none
        cell.deleteAction = { [weak self] in
            self?.users.remove(at: indexPath.row)
            self?.titleLabel.updateCounter(self?.users.count ?? 0)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.reloadData()
        }
        
        return cell
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension NewGroupViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let pickedImage = info[.originalImage] as? UIImage else { return }
        
        let deleteAction = UIAction(
            title: LocalizationManager.shared.localizedString(for: "delete"),
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { action in
            self.sendDeleteImage()
        }
        
        if photoMenu.children.count == 1 {
            var updatedChildren = photoMenu.children
            updatedChildren.append(deleteAction)
            photoMenu = photoMenu.replacingChildren(updatedChildren)
            clearButton.menu = photoMenu
            clearButton.showsMenuAsPrimaryAction = true
        }
        picker.dismiss(animated: true, completion: nil)
        
        showCrop(pickedImage)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func showCrop(_ image: UIImage) {
        let vc = CropViewController(croppingStyle: .circular, image: image)
        vc.aspectRatioPreset = .presetSquare
        vc.aspectRatioLockEnabled = true
        vc.toolbarPosition = .top
        vc.doneButtonTitle = "Continue"
        vc.cancelButtonTitle = "Back"
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        isPhoto = true
        addPickedImage(image)
        cropViewController.dismiss(animated: true)
    }
}

extension NewGroupViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        var newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        let result = newText.count <= Constants.maxGroupNameLength
        if !result {
            newText = String(newText.prefix(Constants.maxGroupNameLength))
        }
        
        updateTextFieldWidth(for: newText)
        
        return result
    }
    
    private func calculateWidth(for text: String) -> CGFloat {
        return min(max(calculateTextWidth(for: text), calculateTextWidth(for: "Group name")), Constants.groupTextFieldWidth)
    }
    
    private func calculateTextWidth(for text: String) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: groupTextField.font ?? Fonts.systemR18]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width + 10
    }
}
