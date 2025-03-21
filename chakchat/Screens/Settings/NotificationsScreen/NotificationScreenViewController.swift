//
//  NotificationScreenViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 31.01.2025.
//

import UIKit

// MARK: - NotificationScreenViewController
final class NotificationScreenViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let arrowLabel: String = "arrow.left"
        static let notificationTableTop: CGFloat = 0
        static let notificationTableBottom: CGFloat = 40
    }

    // MARK: - Properties
    private var titleLabel: UILabel = UILabel()
    private var notificationTableView: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private var notificationData = [
        [LocalizationManager.shared.localizedString(for: "notifications")],
        [LocalizationManager.shared.localizedString(for: "sound"),
         LocalizationManager.shared.localizedString(for: "vibration")]
    ]
    
    let interactor: NotificationScreenBusinessLogic
    
    // MARK: - Initialization
    init(interactor: NotificationScreenBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.backgroundSettings
        configureBackButton()
        configureTitleLabel()
        navigationItem.titleView = titleLabel
        configureNotificationTable()
        interactor.loadUserData()
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
        titleLabel.text = LocalizationManager.shared.localizedString(for: "notifications")
        titleLabel.textAlignment = .center
    }
    
    private func configureNotificationTable() {
        view.addSubview(notificationTableView)
        notificationTableView.delegate = self
        notificationTableView.dataSource = self
        notificationTableView.separatorStyle = .singleLine
        notificationTableView.pinHorizontal(view)
        notificationTableView.pinTop(view.safeAreaLayoutGuide.topAnchor, Constants.notificationTableTop)
        notificationTableView.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, Constants.notificationTableBottom)
        notificationTableView.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.cellIndetifier)
        notificationTableView.backgroundColor = view.backgroundColor
    }
    
    // MARK: - Actions
    @objc
    private func backButtonPressed() {
        interactor.backToSettingsMenu()
    }
}


// MARK: - UITableViewDelegate, UITableViewDataSource
extension NotificationScreenViewController: UITableViewDelegate, UITableViewDataSource {
    
    func configureUserData(_ userData: NotificationScreenModels.NotificationStatus) {
        
        notificationTableView.layoutIfNeeded()
        
        let generalIndexPath = IndexPath(row: 0, section: 0)
        let audioIndexPath = IndexPath(row: 0, section: 1)
        let vibrationIndexPath = IndexPath(row: 1, section: 1)
        if let generalCell = notificationTableView.cellForRow(at: generalIndexPath) as? NotificationCell {
            generalCell.configureSwitch(isOn: userData.generalNotification)
        }
        if let audioCell = notificationTableView.cellForRow(at: audioIndexPath) as? NotificationCell {
            audioCell.configureSwitch(isOn: userData.audioNotification)
        }
        if let vibrationCell = notificationTableView.cellForRow(at: vibrationIndexPath) as? NotificationCell {
            vibrationCell.configureSwitch(isOn: userData.vibrationNotification)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.cellIndetifier, for: indexPath) as? NotificationCell else {
            return UITableViewCell()
        }
        let item = notificationData[indexPath.section][indexPath.row]
        cell.notificationDelegate = self
        cell.configure(title: item)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
        let label = UILabel()
        label.frame = CGRect.init(x: 10, y: 10, width: headerView.frame.width-10, height: headerView.frame.height-10)
        switch section {
        case 0:
            label.text = LocalizationManager.shared.localizedString(for: "general")
        case 1:
            label.text = LocalizationManager.shared.localizedString(for: "notifications_in_app")
        default:
            label.text = nil
        }
        label.font = Fonts.systemR16
        label.textColor = .gray
        headerView.addSubview(label)
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UIConstants.ConfidentialitySpaceBetweenSections
    }
}

// MARK: - NotificationCellDelegate
extension NotificationScreenViewController: NotificationCellDelegate {
    func switchDidToggle(cell: NotificationCell, isOn: Bool) {
        if let indexPath = notificationTableView.indexPath(for: cell) {
            interactor.updateNotififcationSettings(at: indexPath, isOn: isOn)
        }
    }
}
