//
//  AppThemeViewController.swift
//  chakchat
//
//  Created by лизо4ка курунок on 22.02.2025.
//

import UIKit

final class AppThemeViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let arrowLabel: String = "arrow.left"
        static let tableTop: CGFloat = 0
        static let tableBottom: CGFloat = 40
    }
    
    // MARK: - Properties
    private let interactor: AppThemeBusinessLogic
    private let titleLabel: UILabel = UILabel()
    private var appThemeTableView: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private var selectedIndex: IndexPath?
    private var themes = [
        LocalizationManager.shared.localizedString(for: "dark"),
        LocalizationManager.shared.localizedString(for: "light"),
        LocalizationManager.shared.localizedString(for: "system")
    ]
    
    // MARK: - Initialization
    init(interactor: AppThemeBusinessLogic) {
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
        configureBackButton()
        configureTitleLabel()
        navigationItem.titleView = titleLabel
        configureThemeTable()
        markCurrentTheme()
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
        titleLabel.text = LocalizationManager.shared.localizedString(for: "app_theme")
        titleLabel.textAlignment = .center
    }

    private func configureThemeTable() {
        view.addSubview(appThemeTableView)
        appThemeTableView.delegate = self
        appThemeTableView.dataSource = self
        appThemeTableView.separatorStyle = .singleLine
        appThemeTableView.separatorInset = .zero
        appThemeTableView.pinHorizontal(view)
        appThemeTableView.pinTop(view.safeAreaLayoutGuide.topAnchor, Constants.tableTop)
        appThemeTableView.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, Constants.tableBottom)
        appThemeTableView.register(AppThemeCell.self, forCellReuseIdentifier: AppThemeCell.cellIdentifier)
        appThemeTableView.backgroundColor = view.backgroundColor
    }
    
    // MARK: - Supporting Methods
    private func markCurrentTheme() {
        let currentTheme = ThemeManager.shared.currentTheme
        switch currentTheme {
        case .dark:
            selectedIndex = IndexPath(row: 0, section: 0)
        case .light:
            selectedIndex = IndexPath(row: 1, section: 0)
        case .system:
            selectedIndex = IndexPath(row: 2, section: 0)
        }
    }
    
    // MARK: - Actions
    @objc
    private func backButtonPressed() {
        interactor.backToSettingsMenu()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension AppThemeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return themes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AppThemeCell.cellIdentifier, for: indexPath) as? AppThemeCell else {
            return UITableViewCell()
        }

        let item = themes[indexPath.row]
        let isSelected = (indexPath == selectedIndex)
        cell.selectionStyle = .none
        cell.configure(title: item, isSelected: isSelected)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if selectedIndex != indexPath {
            let theme: AppTheme
            
            switch indexPath.row {
            case 0: theme = .dark
            case 1: theme = .light
            case 2: theme = .system
            default: theme = .system
            }
            
            interactor.updateTheme(theme)
            selectedIndex = indexPath
            tableView.reloadData()
        }
    }
}


