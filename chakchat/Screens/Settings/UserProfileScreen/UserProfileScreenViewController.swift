//
//  UserProfileScreenViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 06.02.2025.
//
import UIKit

// MARK: - UserProfileScreenViewController
final class UserProfileScreenViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let arrowName: String = "arrow.left"
        static let iconDefaultName: String = "camera.circle"
        static let iconSize: CGFloat = 100
        static let borderWidth: CGFloat = 5
        static let iconTop: CGFloat = 10
        static let nameLabelTop: CGFloat = 10
        static let userTableHorizontal: CGFloat = -15
        static let userTableBottom: CGFloat = 20
        static let userTableYop: CGFloat = 0
        static let estimateRowHeight: CGFloat = 60
        static let cornerRadius: CGFloat = 50
    }
    
    // MARK: - Properties
    private var titleLabel: UILabel = UILabel()
    private var nameLabel: UILabel = UILabel()
    private var iconImageView: UIImageView = UIImageView()
    private var userTableView: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private let config = UIImage.SymbolConfiguration(pointSize: Constants.iconSize, weight: .light, scale: .default)
    private var userTableViewData: [(title: String, value: String)] = [
        (LocalizationManager.shared.localizedString(for: "username"), ""),
        (LocalizationManager.shared.localizedString(for: "phone"), ""),
        (LocalizationManager.shared.localizedString(for: "date_of_birth"), "")
    ]
    
    let interactor: UserProfileScreenBusinessLogic
    
    // MARK: - Initialization
    init(interactor: UserProfileScreenBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        interactor.loadUserData()
        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: .languageDidChange, object: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Public Methods
    func configureUserData(_ userData: ProfileSettingsModels.ProfileUserData) {
        nameLabel.text = userData.name
        userTableViewData[0].value = userData.username
        userTableViewData[1].value = Format.number(userData.phone) ?? ""
        if let birth = userData.dateOfBirth {
            let formattedBirth = birth.replacingOccurrences(of: "-", with: ".")
            userTableViewData[2].value = formattedBirth
        }
        if let photoURL = userData.photo {
            let image = ImageCacheManager.shared.getImage(for: photoURL as NSURL)
            iconImageView.image = image
            iconImageView.layer.cornerRadius = 50
        } else {
            let image = UIProfilePhoto(userData.name, Constants.iconSize, Constants.borderWidth).getPhoto()
            iconImageView.layer.cornerRadius = 50
            iconImageView.image = image
        }
    }
    
    func updateUserData(_ userData: ProfileSettingsModels.ChangeableProfileUserData) {
        nameLabel.text = userData.name
        userTableViewData[0].value = userData.username
        if let birth = userData.dateOfBirth {
            let formattedBirth = birth.replacingOccurrences(of: "-", with: ".")
            userTableViewData[2].value = formattedBirth
        }
        userTableView.reloadData()
    }
    
    func updatePhoto(_ photo: URL?) {
        if let url = photo {
            let image = ImageCacheManager.shared.getImage(for: url as NSURL)
            iconImageView.image = image
            iconImageView.layer.cornerRadius = 50
        }
    }
    
    // MARK: - UI Confoguration
    private func configureUI() {
        configureBackButton()
        view.backgroundColor = Colors.backgroundSettings
        configureEditButton()
        configureTitleLabel()
        navigationItem.titleView = titleLabel
        configureIcon()
        configureNameLabel()
        configureProfileTableView()
    }
    
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
    
    private func configureTitleLabel() {
        view.addSubview(titleLabel)
        titleLabel.font = Fonts.systemB20
        titleLabel.text = LocalizationManager.shared.localizedString(for: "my_profile")
    }
    
    private func configureIcon() {
        view.addSubview(iconImageView)
        iconImageView.setHeight(Constants.iconSize)
        iconImageView.setWidth(Constants.iconSize)
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
        iconImageView.layer.masksToBounds = true
        iconImageView.pinCenterX(view)
        iconImageView.pinTop(view.safeAreaLayoutGuide.topAnchor, Constants.iconTop)
        let gearImage = UIImage(systemName: Constants.iconDefaultName, withConfiguration: config)
        iconImageView.tintColor = Colors.lightOrange
        iconImageView.image = gearImage
    }
    
    private func configureNameLabel() {
        view.addSubview(nameLabel)
        nameLabel.font = Fonts.systemB20
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        nameLabel.pinTop(iconImageView.bottomAnchor, Constants.nameLabelTop)
        nameLabel.pinCenterX(view)
    }
    
    private func configureProfileTableView() {
        view.addSubview(userTableView)
        userTableView.delegate = self
        userTableView.dataSource = self
        userTableView.separatorStyle = .singleLine
        userTableView.separatorInset = .zero
        userTableView.isUserInteractionEnabled = false
        userTableView.pinHorizontal(view, Constants.userTableHorizontal)
        userTableView.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, Constants.userTableBottom)
        userTableView.pinTop(nameLabel.bottomAnchor, Constants.userTableYop)
        userTableView.register(UserProfileCell.self, forCellReuseIdentifier: UserProfileCell.cellIdentifier)
        userTableView.backgroundColor = view.backgroundColor
        userTableView.rowHeight = UITableView.automaticDimension
        userTableView.estimatedRowHeight = Constants.estimateRowHeight
    }
    
    // MARK: - Actions
    @objc
    private func backButtonPressed() {
        interactor.backToSettingsMenu()
    }
    
    @objc
    private func editButtonPressed() {
        interactor.profileSettingsRoute()
    }
    
    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc
    private func languageDidChange() {
        titleLabel.text = LocalizationManager.shared.localizedString(for: "my_profile")
        titleLabel.sizeToFit()
        navigationItem.rightBarButtonItem?.title = LocalizationManager.shared.localizedString(for: "edit")
        userTableViewData[0].title = LocalizationManager.shared.localizedString(for: "username")
        userTableViewData[1].title = LocalizationManager.shared.localizedString(for: "phone")
        userTableViewData[2].title = LocalizationManager.shared.localizedString(for: "date_of_birth")
        userTableView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension UserProfileScreenViewController: UITableViewDelegate, UITableViewDataSource {
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

