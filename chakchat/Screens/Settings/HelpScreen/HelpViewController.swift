//
//  HelpViewController.swift
//  chakchat
//
//  Created by лизо4ка курунок on 23.02.2025.
//

import UIKit
import SafariServices

final class HelpViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let arrowLabel: String = "arrow.left"
        static let versionBottom: CGFloat = 30
        static let chakchatBottom1: CGFloat = 4
        static let chakchatBottom2: CGFloat = 30
        static let tableHorizontal: CGFloat = -5
        static let tableTop: CGFloat = 20
        static let tableBottom: CGFloat = 15
    }
    
    // MARK: - Properties
    private let interactor: HelpBusinessLogic
    private let titleLabel: UILabel = UILabel()
    private let versionLabel: UILabel = UILabel()
    private let chakchatLabel: UILabel = UILabel()
    private let tableView: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections = [
        [LocalizationManager.shared.localizedString(for: "report_bug"),
         LocalizationManager.shared.localizedString(for: "send_review"),
         "FAQ"
        ],
        [LocalizationManager.shared.localizedString(for: "write_email"),
         LocalizationManager.shared.localizedString(for: "write_support_chat")
        ]
    ]
    
    // MARK: - Initialization
    init(interactor: HelpBusinessLogic) {
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
        configureVersionLabel()
        configureChakChatLabel()
        configureTableView()
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
        titleLabel.text = LocalizationManager.shared.localizedString(for: "help")
        titleLabel.textAlignment = .center
    }
    
    private func configureVersionLabel() {
        if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            view.addSubview(versionLabel)
            versionLabel.text = LocalizationManager.shared.localizedString(for: "version") + " " + appVersion
            versionLabel.textAlignment = .center
            versionLabel.numberOfLines = 1
            versionLabel.textColor = Colors.text
            
            versionLabel.pinCenterX(view)
            versionLabel.pinBottom(view, Constants.versionBottom)
        }
    }
    
    private func configureChakChatLabel() {
        view.addSubview(chakchatLabel)
        chakchatLabel.text = "ChakChat"
        chakchatLabel.textAlignment = .center
        chakchatLabel.textColor = Colors.text
        chakchatLabel.font = Fonts.systemSB20
        chakchatLabel.pinCenterX(view)
        if versionLabel.text != nil {
            chakchatLabel.pinBottom(versionLabel.topAnchor, Constants.chakchatBottom1)
        } else {
            chakchatLabel.pinBottom(view, Constants.chakchatBottom2)
        }
    }
    
    private func configureTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        tableView.pinHorizontal(view, Constants.tableHorizontal)
        tableView.pinTop(view, Constants.tableTop)
        tableView.pinBottom(chakchatLabel.topAnchor, Constants.tableBottom)
        tableView.register(HelpCell.self, forCellReuseIdentifier: HelpCell.cellIdentifier)
        tableView.backgroundColor = view.backgroundColor
    }
    
    // MARK: - Supporting Methods
    private func FAQ() {
        // TODO: add link to FAQ
        if let url = URL(string: "https://github.com/chakchat/chakchat-ios/blob/main/Docs") {
            let safariVC = SFSafariViewController(url: url)
            safariVC.modalPresentationStyle = .formSheet
            present(safariVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Actions
    @objc
    private func backButtonPressed() {
        interactor.backToSettingsMenu()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension HelpViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
        
        let label = UILabel()
        label.frame = CGRect.init(
            x: 10,
            y: 0,
            width: headerView.frame.width - 10,
            height: headerView.frame.height - 10
        )
        switch section {
        case 1:
            label.text = LocalizationManager.shared.localizedString(for: "not_find_answer")
        default:
            label.text = nil
        }
        label.font = Fonts.systemR16
        label.textColor = .gray
        headerView.addSubview(label)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let helpCell = tableView.dequeueReusableCell(withIdentifier: HelpCell.cellIdentifier, for: indexPath) as? HelpCell
        else {
            return UITableViewCell()
        }
        let item = sections[indexPath.section][indexPath.row]
        helpCell.configure(with: item)
        return helpCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        // if pressed cell is "Report a bug"
        case (0, 0):
            interactor.sendErrorMail(self)
        // if pressed cell is "Send review"
        case (0, 1):
            interactor.reviewInAppStore()
        // if pressed cell is "FAQ"
        case (0, 2):
            FAQ()
        // if pressed cell is "Write to us by email"
        case (1, 0):
            interactor.sendEmptyMail(self)
        // if pressed cell is ""Write to support in chat"
        case (1, 1): break
            // link to support chat in messanger
        default:
            break
        }
    }
}

