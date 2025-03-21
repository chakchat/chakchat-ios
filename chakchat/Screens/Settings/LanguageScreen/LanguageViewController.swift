//
//  LanguageViewController.swift
//  chakchat
//
//  Created by лизо4ка курунок on 15.02.2025.
//

import UIKit

// MARK: - LanguageViewController
final class LanguageViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let headerText: String = LocalizationManager.shared.localizedString(for: "Language")
        static let arrowLabel: String = "arrow.left"
        static let tableTop: CGFloat = 0
        static let tableBottom: CGFloat = 40
    }
    
    // MARK: - Properties
    private let interactor: LanguageBusinessLogic
    
    private var selectedIndex: IndexPath?
    private var titleLabel: UILabel = UILabel()
    private var languages = [
        [LocalizationManager.shared.localizedString(for: "english"), "English"],
        [LocalizationManager.shared.localizedString(for: "russian"), "Русский"],
        [LocalizationManager.shared.localizedString(for: "italian"), "Italiano"]
    ]
    private var isLoadingIndex: IndexPath? = nil
    private var languageTableView: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Initialization
    init(interactor: LanguageBusinessLogic) {
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
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Colors.backgroundSettings
        configureBackButton()
        configureTitleLabel()
        navigationItem.titleView = titleLabel
        configureLanguageTable()
        markCurrentLanguage()
        languageDidChange()
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
        titleLabel.text = Constants.headerText
        titleLabel.textAlignment = .center
    }
    
    private func configureLanguageTable() {
        view.addSubview(languageTableView)
        languageTableView.delegate = self
        languageTableView.dataSource = self
        languageTableView.separatorStyle = .singleLine
        languageTableView.separatorInset = .zero
        languageTableView.pinHorizontal(view)
        languageTableView.pinTop(view.safeAreaLayoutGuide.topAnchor, Constants.tableTop)
        languageTableView.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, Constants.tableBottom)
        languageTableView.register(LanguageCell.self, forCellReuseIdentifier: LanguageCell.cellIdentifier)
        languageTableView.backgroundColor = view.backgroundColor
    }
    
    // MARK: - Actions
    @objc
    private func backButtonPressed() {
        interactor.backToSettingsMenu()
    }
    
    @objc
    private func languageDidChange() {
        titleLabel.text = LocalizationManager.shared.localizedString(for: "Language")
        titleLabel.sizeToFit()
        languages[0][0] = LocalizationManager.shared.localizedString(for: "english")
        languages[1][0] = LocalizationManager.shared.localizedString(for: "russian")
        languages[2][0] = LocalizationManager.shared.localizedString(for: "italian")
        languageTableView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension LanguageViewController: UITableViewDelegate, UITableViewDataSource {
    
    public func markCurrentLanguage() {
        var rowIndex: Int
        let currentLanguage = LocalizationManager.shared.getCode()
        print(currentLanguage)
        switch currentLanguage {
        case "en":
            rowIndex = 0
        case "ru":
            rowIndex = 1
        case "it":
            rowIndex = 2
        default:
            rowIndex = 0
            break
        }
        selectedIndex = IndexPath(row: rowIndex, section: 0)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LanguageCell.cellIdentifier, for: indexPath) as? LanguageCell else {
            return UITableViewCell()
        }

        let item = languages[indexPath.row]
        let isSelected = (indexPath == selectedIndex)
        let isLoading = (indexPath == isLoadingIndex)
        cell.selectionStyle = .none
        cell.configure(title: item, isSelected: isSelected, isLoading: isLoading)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if selectedIndex != indexPath {
            isLoadingIndex = indexPath
            tableView.reloadRows(at: [indexPath], with: .none)

            let selectedLanguage: String
            switch indexPath.row {
            case 0: selectedLanguage = "en"
            case 1: selectedLanguage = "ru"
            case 2: selectedLanguage = "it"
            default: selectedLanguage = "en"
            }

            interactor.updateLanguage(to: selectedLanguage) {
                DispatchQueue.main.async {
                    self.selectedIndex = indexPath
                    self.isLoadingIndex = nil
                    tableView.reloadData()
                }
            }
        }
    }
}

