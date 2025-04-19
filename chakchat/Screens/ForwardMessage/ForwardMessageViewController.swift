//
//  ForwardMessageViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 19.04.2025.
//

import UIKit

final class ForwardMessageViewController: UIViewController {
    
    private let interactor: ForwardMessageBusinessLogic
    private var chatsTableView: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    private var chats: [ChatsModels.GeneralChatModel.ChatData] = [] { didSet { chatsTableView.reloadData() } }
    
    init(interactor: ForwardMessageBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func showForwardState(_ message: String, _ status: Bool) {
        let messageView = UIView()
        messageView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.9)
        messageView.layer.cornerRadius = 12
        messageView.clipsToBounds = true
        messageView.alpha = 0
        
        let label = UILabel()
        label.text = message
        label.textColor = status ? .green : .red
        label.textAlignment = .center
        label.numberOfLines = 0
        
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        
        messageView.addSubview(label)
        messageView.addSubview(image)
        
        label.pinTop(messageView.topAnchor, 16)
        label.pinHorizontal(messageView)
        
        image.pinCenterX(messageView.centerXAnchor)
        image.pinCenterY(messageView.centerYAnchor)
        image.setHeight(150)
        image.setWidth(150)
        image.image = status ? UIImage(systemName: "checkmark.seal.fill") : UIImage(systemName: "xmark.seal.fill")
        image.tintColor = status ? .green : .red
        
        view.addSubview(messageView)
        
        messageView.pinCenterX(view.centerXAnchor)
        messageView.pinCenterY(view.centerYAnchor)
        messageView.setHeight(200)
        messageView.setHeight(200)
        
        UIView.animate(withDuration: 0.3) {
            messageView.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 1.0) {
                messageView.alpha = 0
            } completion: { _ in
                messageView.removeFromSuperview()
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.chats = interactor.loadChatData()
        configureUI()
    }
    
    private func configureUI() {
        configureChatsTableView()
    }
    
    private func configureChatsTableView() {
        view.addSubview(chatsTableView)
        chatsTableView.pinTop(view.safeAreaLayoutGuide.topAnchor, 0)
        chatsTableView.pinBottom(view.safeAreaLayoutGuide.bottomAnchor, 0)
        chatsTableView.pinLeft(view.safeAreaLayoutGuide.leadingAnchor, 0)
        chatsTableView.pinRight(view.safeAreaLayoutGuide.trailingAnchor, 0)
        chatsTableView.register(UISearchControllerCell.self, forCellReuseIdentifier: UISearchControllerCell.cellIdentifier)
        chatsTableView.delegate = self
        chatsTableView.dataSource = self
    }
}

extension ForwardMessageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = chats[indexPath.row]
        interactor.forwardMessage(cell.chatID)
    }
}

extension ForwardMessageViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UISearchControllerCell.cellIdentifier, for: indexPath) as? UISearchControllerCell else { return UITableViewCell() }
        let chat = chats[indexPath.row]
        if case .personal(_) = chat.info {
            interactor.getUserInfo(chat.members) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let userData):
                        cell.configure(userData.photo, userData.name, deletable: false)
                    case .failure(_):
                        let alert = UIAlertController(title: "Not all chats was fetched, be carefull", message: nil, preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .cancel)
                        alert.addAction(ok)
                        self.present(alert, animated: true)
                    }
                }
            }
            return cell
        }
        if case .group(let groupInfo) = chat.info {
            cell.configure(groupInfo.groupPhoto, groupInfo.name, deletable: false)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
