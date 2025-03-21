//
//  BirthVisibilityScreenViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 30.01.2025.
//

import Foundation
import UIKit

// MARK: - BirthVisibilityScreenViewController
final class BirthVisibilityScreenViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let arrowName: String = "arrow.left"
    }
    
    // MARK: - Properties
    private var selectedIndex: IndexPath = IndexPath()
    private var titleLabel: UILabel = UILabel()
    private var birthVisibilityTable: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private var birthVisibilityData = [
        [(LocalizationManager.shared.localizedString(for: "everyone")),
         (LocalizationManager.shared.localizedString(for: "only_me")),
         (LocalizationManager.shared.localizedString(for: "specified"))],
        [(LocalizationManager.shared.localizedString(for: "users_list")),]
    ]
    let interactor: BirthVisibilityScreenBusinessLogic
    
    // MARK: - Initialization
    init(interactor: BirthVisibilityScreenBusinessLogic) {
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
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.backgroundSettings
        interactor.loadUserRestrictions()
        configureBackButton()
        configureTitleLabel()
        navigationItem.titleView = titleLabel
        configurePhoneVisibilityTable()
    }
    
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.arrowName), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.text
        // Adding returning to previous screen with swipe.
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    private func configureTitleLabel() {
        view.addSubview(titleLabel)
        titleLabel.font = Fonts.systemB20
        titleLabel.text = LocalizationManager.shared.localizedString(for: "date_of_birth")
        titleLabel.textAlignment = .center
    }
    
    private func configurePhoneVisibilityTable() {
        view.addSubview(birthVisibilityTable)
        birthVisibilityTable.delegate = self
        birthVisibilityTable.dataSource = self
        birthVisibilityTable.separatorStyle = .singleLine
        birthVisibilityTable.pinHorizontal(view)
        birthVisibilityTable.pinTop(view.safeAreaLayoutGuide.topAnchor, 0)
        birthVisibilityTable.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, 20)
        birthVisibilityTable.register(VisibilityCell.self, forCellReuseIdentifier: VisibilityCell.cellIdentifier)
        birthVisibilityTable.register(ExceptionsCell.self, forCellReuseIdentifier: ExceptionsCell.cellIdentifier)
        birthVisibilityTable.backgroundColor = view.backgroundColor
    }
    
    // MARK: - Supporting Methods
    // Edits the second section depending on what is selected in the first
    private func updateExceptionsSection() {
        switch selectedIndex.row {
        case 2:
            birthVisibilityData[1] = [(LocalizationManager.shared.localizedString(for: "users_list"))]
        default:
            break
        }
    }
    
    private func transferRestriction() -> String {
        switch selectedIndex.row {
        case 0:
            return "everyone"
        case 1:
            return "only_me"
        case 2:
            return "specified"
        default:
            break
        }
        return "everyone"
    }
    
    // MARK: - Actions
    @objc
    private func backButtonPressed() {
        let birthRestriction = transferRestriction()
        interactor.backToConfidentialityScreen(birthRestriction)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension BirthVisibilityScreenViewController: UITableViewDelegate, UITableViewDataSource {
    
    // Called during screen configuration to check the box depending on the data in the user defaults storage
    public func markCurrentOption(_ userRestrictions: ConfidentialitySettingsModels.ConfidentialityUserData) {
        var rowIndex: Int
        print(userRestrictions.dateOfBirth.openTo)
        switch userRestrictions.dateOfBirth.openTo {
        case "everyone":
            rowIndex = 0
        case "only_me":
            rowIndex = 1
        case "specified":
            rowIndex = 2
        default:
            rowIndex = 0
            break
        }
        selectedIndex = IndexPath(row: rowIndex, section: 0)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return birthVisibilityData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return birthVisibilityData[section].count
        } else {
            return (selectedIndex.row == 2) ? birthVisibilityData[section].count : 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: VisibilityCell.cellIdentifier, for: indexPath) as? VisibilityCell else {
                return UITableViewCell()
            }
            let item = birthVisibilityData[indexPath.section][indexPath.row]
            let isSelected = (indexPath == selectedIndex)
            cell.configure(title: item, isSelected: isSelected)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ExceptionsCell.cellIdentifier, for: indexPath) as? ExceptionsCell else {
                return UITableViewCell()
            }
            if selectedIndex.row == 2 {
                let item = birthVisibilityData[indexPath.section][indexPath.row]
                cell.configure(title: item)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
        let label = UILabel()
        // where exactly the title will be located relative to the section
        label.frame = CGRect.init(x: 10, y: 10, width: headerView.frame.width-10, height: headerView.frame.height-10)
        switch section {
        case 0:
            label.text = LocalizationManager.shared.localizedString(for: "who_can_see_birth")
        case 1:
            if selectedIndex.row != 2 {
                break
            }
            label.text = LocalizationManager.shared.localizedString(for: "exceptions")
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            if selectedIndex != indexPath {
                selectedIndex = indexPath
            }
            updateExceptionsSection()
            tableView.reloadData()
        } else {
            // the logic of the second section has not yet been invented
        }
    }
}
