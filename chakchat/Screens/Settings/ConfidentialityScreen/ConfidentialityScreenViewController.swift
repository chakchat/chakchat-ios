//
//  ConfidentialityScreenViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 28.01.2025.
//

import Foundation
import UIKit

// MARK: - ConfidentialityScreenViewController
final class ConfidentialityScreenViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let tableTop: CGFloat = 0
        static let tableBottom: CGFloat = 20
        static let arrowName: String = "arrow.left"
    }
    
    // MARK: - Properties
    private var titleLabel: UILabel = UILabel()
    private var confidentialitySettingsTable: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private var confidentilitySection = [
        (LocalizationManager.shared.localizedString(for: "phone_number"), LocalizationManager.shared.localizedString(for: "everyone")),
        (LocalizationManager.shared.localizedString(for: "date_of_birth"), LocalizationManager.shared.localizedString(for: "everyone")),
        (LocalizationManager.shared.localizedString(for: "online_status"), LocalizationManager.shared.localizedString(for: "everyone")),
        (LocalizationManager.shared.localizedString(for: "black_list"), "")
    ]
    
    let interactor: ConfidentialityScreenBusinessLogic
    
    // MARK: - Initialization
    init(interactor: ConfidentialityScreenBusinessLogic) {
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
    
    // MARK: - Public Methods
    func configureSections(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData) {
        confidentilitySection[0].1 = LocalizationManager.shared.localizedString(for: userRestrictions.phone.openTo)
        confidentilitySection[1].1 = LocalizationManager.shared.localizedString(for: userRestrictions.dateOfBirth.openTo)
        DispatchQueue.main.async {
            self.confidentialitySettingsTable.reloadData()
        }
    }
    
    // MARK: - Visibility Status Updating
    func updateVisibilityStatus(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData) {
        confidentilitySection[0].1 = LocalizationManager.shared.localizedString(for: userRestrictions.phone.openTo)
        confidentilitySection[1].1 = LocalizationManager.shared.localizedString(for: userRestrictions.dateOfBirth.openTo)
        confidentialitySettingsTable.reloadData()
    }
    // TODO: подумать, что делать с этим всем. Нужно конфигурировать вместе.
    /// проблема в том что Булат пока сам не знает, будем ли мы изменять видимость онлайн статуса или не будем
    /// пока сделаю такой костыль
    func configureOnlineStatus(_ onlineRestriction: OnlineVisibilityStatus) {
        confidentilitySection[2].1 = LocalizationManager.shared.localizedString(for: onlineRestriction.status)
    }
    
    func updateOnlineStatus(_ onlineRestriction: OnlineVisibilityStatus) {
        confidentilitySection[2].1 = LocalizationManager.shared.localizedString(for: onlineRestriction.status)
        confidentialitySettingsTable.reloadData()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.backgroundSettings
        configureBackButton()
        configureSettingsTable()
        interactor.loadUserData()
        configureTitleLabel()
        navigationItem.titleView = titleLabel
    }
    
    private func configureTitleLabel() {
        view.addSubview(titleLabel)
        titleLabel.font = Fonts.systemB18
        titleLabel.text = LocalizationManager.shared.localizedString(for: "confidantiality")
        titleLabel.textAlignment = .center
    }

    private func configureSettingsTable() {
        view.addSubview(confidentialitySettingsTable)
        confidentialitySettingsTable.delegate = self
        confidentialitySettingsTable.dataSource = self
        confidentialitySettingsTable.separatorStyle = .singleLine
        confidentialitySettingsTable.separatorInset = .zero
        confidentialitySettingsTable.pinHorizontal(view)
        confidentialitySettingsTable.pinTop(view.safeAreaLayoutGuide.topAnchor, Constants.tableTop)
        confidentialitySettingsTable.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, Constants.tableBottom)
        confidentialitySettingsTable.register(ConfidentialityMenuCell.self, forCellReuseIdentifier: ConfidentialityMenuCell.cellIdentifier)
        confidentialitySettingsTable.register(BlackListCell.self, forCellReuseIdentifier: BlackListCell.cellIdentifier)
        confidentialitySettingsTable.backgroundColor = view.backgroundColor
    }
    
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.arrowName), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.text
        // Adding returning to previous screen with swipe.
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    // MARK: - Actions
    @objc
    private func backButtonPressed() {
        interactor.backToSettingsMenu()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ConfidentialityScreenViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ConfidentialityMenuCell.cellIdentifier, for: indexPath) as? ConfidentialityMenuCell else {
            return UITableViewCell()
        }
        let item = confidentilitySection[indexPath.row]
        cell.configureSettings(title: item.0, status: item.1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (0,0):
            interactor.routeToPhoneVisibilityScreen()
        case (0,1):
            interactor.routeToBirthVisibilityScreen()
            break
        case (0,2):
            interactor.routeToOnlineVisibilityScreen()
            break
        case (0,3):
            interactor.routeToBlackListScreen()
            break
        default:
            break
        }
    }
}
