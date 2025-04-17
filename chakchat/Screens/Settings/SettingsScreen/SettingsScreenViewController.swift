//
//  SettingsScreenViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 21.01.2025.
//

import Foundation
import UIKit

// MARK: - SettingsScreenViewController
final class SettingsScreenViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let iconImageSize: CGFloat = 80
        static let borderWidth: CGFloat = 3
        static let defaultProfileImageSymbol: String = "camera.circle"
        static let backArrowSymbol: String = "arrow.left"
        static let iconTop: CGFloat = 10
        static let settingsTableHorizontal: CGFloat = -15
        static let settingsTableTop: CGFloat = 5
        static let settingsTableBottom: CGFloat = 20
        static let nicknameLabelTop: CGFloat = 10
        static let dotText: String = "•"
        static let atText: String = "@"
        static let dataStackViewSpacing: CGFloat = 10
        static let dataStackViewTop: CGFloat = 5
        static let tableHeaderHeight: CGFloat = 50
        static let tableHeaderX: CGFloat = 0
        static let tableHeaderY: CGFloat = 0
        static let tableLabelX: CGFloat = 10
        static let tableLabelY: CGFloat = 0
        static let tableLabelDifferenceToHeader: CGFloat = -10
        static let labelFontSize: CGFloat = 12
        static let spaceBetweenSections: CGFloat = 30
        static let cornerRadius: CGFloat = 40
    }
    
    // MARK: - Properties
    var interactor: SettingsScreenBusinessLogic

    private var settingsTableView: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private var settingsLabel: UILabel = UILabel()
    private var nicknameLabel: UILabel = UILabel()
    private var usernameLabel: UILabel = UILabel()
    private var phoneLabel: UILabel = UILabel()
    private var dotLabel: UILabel = UILabel()
    private var headerLabels: [Int: UILabel] = [:]
    private lazy var dataStackView: UIStackView = UIStackView(arrangedSubviews: [phoneLabel, dotLabel, usernameLabel])
    let config = UIImage.SymbolConfiguration(pointSize: Constants.iconImageSize, weight: .light, scale: .default)
    
    private let iconImageView: UIImageView = UIImageView()
    private var sections = [
        [(LocalizationManager.shared.localizedString(for: "my_profile"), UIImage(systemName: "person.crop.circle"))],
        [(LocalizationManager.shared.localizedString(for: "confidantiality"), UIImage(systemName: "lock")),
         (LocalizationManager.shared.localizedString(for: "notifications"), UIImage(systemName: "bell"))
        ],
        [(LocalizationManager.shared.localizedString(for: "data_and_memory"), UIImage(systemName: "memorychip")),
         (LocalizationManager.shared.localizedString(for: "app_theme"), UIImage(systemName: "cloud.moon.fill")),
         (LocalizationManager.shared.localizedString(for: "Language"), UIImage(systemName: "globe.europe.africa.fill"))
        ],
        [(LocalizationManager.shared.localizedString(for: "help"), UIImage(systemName: "questionmark.bubble"))]
    ]
    
    // MARK: - Initialization
    init(interactor: SettingsScreenBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: .languageDidChange, object: nil)
        configureUI()
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            guard let text = nicknameLabel.text else { return }
            let image = UIProfilePhoto(text, Constants.iconImageSize, Constants.borderWidth).getPhoto()
            iconImageView.image = image
        }
    }
    
    // MARK: - Public Methods
    func configureUserData(_ data: ProfileSettingsModels.ProfileUserData) {
        let image = UIProfilePhoto(data.name, Constants.iconImageSize, Constants.borderWidth).getPhoto()
        iconImageView.image = image
        
        if let imageURL = data.photo {
            if let image = ImageCacheManager.shared.getImage(for: imageURL as NSURL) {
                iconImageView.image = image
                iconImageView.layer.cornerRadius = 40
            } else {
                interactor.loadPhotoByURL(imageURL) { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        switch result {
                        case .success(let image):
                            self.iconImageView.image = image
                            self.iconImageView.layer.cornerRadius = 40
                            ImageCacheManager.shared.saveImage(image, for: imageURL as NSURL)
                        case .failure(_):
                            print("Failed to download file")
                        }
                    }
                }
            }
        }
        configureNicknameLabel(data.name)
        configureDataStackView(data.username, data.phone)
    }
    
    // MARK: - UserData Update
    func updateUserData(_ data: ProfileSettingsModels.ChangeableProfileUserData) {
        nicknameLabel.text = data.name
        usernameLabel.text = data.username
    }
    
    func updatePhoto(_ photo: URL?) {
        DispatchQueue.main.async {
            if let url = photo {
                self.iconImageView.image = ImageCacheManager.shared.getImage(for: url as NSURL)
                self.iconImageView.layer.cornerRadius = 40
            }
        }
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.backgroundSettings
        configureSettingsLabel()
        navigationItem.titleView = settingsLabel
        configureBackButton()
        configureIconImageView()
        interactor.loadUserData()
        configureSettingTableView()
    }
    
    private func configureSettingsLabel() {
        view.addSubview(settingsLabel)
        settingsLabel.font = Fonts.systemB20
        settingsLabel.text = LocalizationManager.shared.localizedString(for: "settings")
    }

    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.backArrowSymbol), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.text
        // Adding returning to previous screen with swipe.
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }

    private func configureIconImageView() {
        view.addSubview(iconImageView)
        iconImageView.setHeight(Constants.iconImageSize)
        iconImageView.setWidth(Constants.iconImageSize)
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.layer.cornerRadius = Constants.cornerRadius
        iconImageView.layer.masksToBounds = true
        iconImageView.pinCenterX(view)
        iconImageView.pinTop(view.safeAreaLayoutGuide.topAnchor, Constants.iconTop)
        iconImageView.tintColor = Colors.lightOrange
    }
    
    private func configureSettingTableView() {
        view.addSubview(settingsTableView)
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.separatorStyle = .singleLine
        settingsTableView.separatorInset = .zero
        settingsTableView.pinHorizontal(view, Constants.settingsTableHorizontal)
        settingsTableView.pinTop(dataStackView.bottomAnchor, Constants.settingsTableTop)
        settingsTableView.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, Constants.settingsTableBottom)
        settingsTableView.register(SettingsMenuCell.self, forCellReuseIdentifier: SettingsMenuCell.cellIdentifier)
        settingsTableView.backgroundColor = view.backgroundColor
    }
    
    private func configureNicknameLabel(_ nickname: String) {
        view.addSubview(nicknameLabel)
        nicknameLabel.pinCenterX(view)
        nicknameLabel.pinTop(iconImageView.bottomAnchor, Constants.nicknameLabelTop)
        nicknameLabel.font = Fonts.systemSB20
        nicknameLabel.text = nickname
    }

    private func configureDataStackView(_ username: String?, _ phone: String?) {
        view.addSubview(phoneLabel)
        view.addSubview(usernameLabel)
        view.addSubview(dotLabel)
        phoneLabel.font = Fonts.systemL14
        phoneLabel.text = Format.number(phone ?? LocalizationManager.shared.localizedString(for: "loading."))
        phoneLabel.textColor = .gray
        phoneLabel.textAlignment = .center
        
        dotLabel.font = Fonts.systemB16
        dotLabel.text = Constants.dotText
        dotLabel.textColor = .gray
        dotLabel.textAlignment = .center
        
        usernameLabel.font = Fonts.systemL14
        usernameLabel.text = Constants.atText + (username ?? LocalizationManager.shared.localizedString(for: "loading."))
        usernameLabel.textColor = .gray
        usernameLabel.textAlignment = .center
        
        view.addSubview(dataStackView)
        dataStackView.axis = .horizontal
        dataStackView.alignment = .center
        dataStackView.spacing = Constants.dataStackViewSpacing
        dataStackView.pinCenterX(view)
        dataStackView.pinTop(nicknameLabel.bottomAnchor, Constants.dataStackViewTop)
        
    }
    
    // MARK: - Actions
    @objc
    private func backButtonPressed() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc
    private func languageDidChange() {
        settingsLabel.text = LocalizationManager.shared.localizedString(for: "settings")
        settingsLabel.sizeToFit()
        sections = [
            [(LocalizationManager.shared.localizedString(for: "my_profile"), UIImage(systemName: "person.crop.circle"))],
            [(LocalizationManager.shared.localizedString(for: "confidantiality"), UIImage(systemName: "lock")),
             (LocalizationManager.shared.localizedString(for: "notifications"), UIImage(systemName: "bell"))
            ],
            [(LocalizationManager.shared.localizedString(for: "data_and_memory"), UIImage(systemName: "memorychip")),
             (LocalizationManager.shared.localizedString(for: "app_theme"), UIImage(systemName: "cloud.moon.fill")),
             (LocalizationManager.shared.localizedString(for: "Language"), UIImage(systemName: "globe.europe.africa.fill"))
            ],
            [(LocalizationManager.shared.localizedString(for: "help"), UIImage(systemName: "questionmark.bubble"))]
        ]
        settingsTableView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SettingsScreenViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: Constants.tableHeaderX, y: Constants.tableHeaderY, width: tableView.frame.width, height: Constants.tableHeaderHeight))
        
        let label = UILabel()
        label.frame = CGRect.init(
            x: Constants.tableLabelX,
            y: Constants.tableLabelY,
            width: headerView.frame.width + Constants.tableLabelDifferenceToHeader,
            height: headerView.frame.height + Constants.tableLabelDifferenceToHeader
        )
        switch section {
        case 0:
            label.text = LocalizationManager.shared.localizedString(for: "user")
        case 1:
            label.text = LocalizationManager.shared.localizedString(for: "general")
        case 2:
            label.text = LocalizationManager.shared.localizedString(for: "app")
        case 3:
            label.text = LocalizationManager.shared.localizedString(for: "support")
        default:
            label.text = nil
        }
        label.font = .systemFont(ofSize: Constants.labelFontSize)
        label.textColor = .gray
        headerView.addSubview(label)
        headerLabels[section] = label
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.spaceBetweenSections
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let settingsCell = tableView.dequeueReusableCell(withIdentifier: SettingsMenuCell.cellIdentifier, for: indexPath) as? SettingsMenuCell
        else {
            return UITableViewCell()
        }
        let item = sections[indexPath.section][indexPath.row]
        settingsCell.configure(with: item.0, with: item.1)
        return settingsCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        // if pressed cell is "My Profile"
        case (0,0):
            interactor.profileSettingsRoute()
        // if pressed cell is "Confidentiality"
        case (1,0):
            interactor.confidentialitySettingsRoute()
        // if pressed cell is "Notification"
        case (1,1):
            interactor.notificationSettingsRoute()
        // if pressed cell is "Language"
        case (2, 2):
            interactor.languageSettingsRoute()
        // if pressed cell is "App theme"
        case (2, 1):
            interactor.appThemeSettingsRoute()
        // if pressed cell is "Data and memory"
        case (2, 0):
            interactor.cacheSettingsRoute()
        // if pressed cell is "Help"
        case (3, 0):
            interactor.helpSettingsRoute()
        default:
            break
        }
    }
}
