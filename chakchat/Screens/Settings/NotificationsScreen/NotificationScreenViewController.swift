//
//  NotificationScreenViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 31.01.2025.
//

import Foundation
import UIKit

final class NotificationScreenViewController: UIViewController {
    
    private var notificationTableView: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private var notificationData = [
        [("Notification")],
        [("Sound"), ("Vibration")]
    ]
    let interactor: NotificationScreenBusinessLogic
    
    init(interactor: NotificationScreenBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    private func configureUI() {
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.left"), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = .black
        configureNotificationTable()
        interactor.loadUserData()
    }
    
    private func configureNotificationTable() {
        view.addSubview(notificationTableView)
        notificationTableView.delegate = self
        notificationTableView.dataSource = self
        notificationTableView.separatorStyle = .singleLine
        notificationTableView.pinHorizontal(view)
        notificationTableView.pinTop(view.safeAreaLayoutGuide.topAnchor, 20)
        notificationTableView.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, 40)
        notificationTableView.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.cellIndetifier)
        notificationTableView.backgroundColor = view.backgroundColor
    }
    
    @objc
    private func backButtonPressed() {
        interactor.backToSettingsMenu()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension NotificationScreenViewController: UITableViewDelegate, UITableViewDataSource {
    
    public func configureUserData(_ userData: NotificationScreenModels.NotificationStatus) {
        
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
    
    // Тут мы настраиваем заголовок к каждой секции
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
        let label = UILabel()
        // вот эта штучка ответственна за то, где именно будет располагаться заголовок относительно секции
        label.frame = CGRect.init(x: 10, y: 10, width: headerView.frame.width-10, height: headerView.frame.height-10)
        switch section {
        case 0:
            label.text = "General"
        case 1:
            label.text = "Notifications in app"
        default:
            label.text = nil
        }
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        headerView.addSubview(label)
        return headerView
    }
    // отвечает за расстояние между хедерами в разных секциях
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}

extension NotificationScreenViewController: NotificationCellDelegate {
    func switchDidToggle(cell: NotificationCell, isOn: Bool) {
        if let indexPath = notificationTableView.indexPath(for: cell) {
            interactor.updateNotififcationSettings(at: indexPath, isOn: isOn)
        }
    }
}
