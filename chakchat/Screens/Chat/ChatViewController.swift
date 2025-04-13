//
//  ChatViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 03.03.2025.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import PhotosUI
import DifferenceKit

// MARK: - ChatViewController
final class ChatViewController: MessagesViewController {
    // MARK: - Constants
    enum Constants {
        static let navigationItemHeight: CGFloat = 44
        static let borderWidth: CGFloat = 5
        static let cornerRadius: CGFloat = 22
        static let spacing: CGFloat = 12
        static let arrowName: String = "arrow.left"
        static let messageInputViewHorizontal: CGFloat = 8
        static let messageInputViewHeigth: CGFloat = 50
        static let messageInputViewBottom: CGFloat = 0
        static let extraKeyboardIndent: CGFloat = 20
        static let outgoingAvatarOverlap: CGFloat = 17.5
    }
    
    // MARK: - Properties
    private let interactor: ChatBusinessLogic
    private let iconImageView: UIImageView = UIImageView()
    private let nicknameLabel: UILabel = UILabel()
    private var tapGesture: UITapGestureRecognizer?
    private let newChatAlert: UINewChatAlert = UINewChatAlert()
    private lazy var expirationButton: UIButton = UIButton(type: .system)
    private var gradientView: ChatBackgroundGradientView = ChatBackgroundGradientView()
    
    private let blockInputBar: UIView = UIView()
    
    private var curUser: SenderPerson = SenderPerson(senderId: UUID().uuidString, displayName: "temp")
    
    private var messages: [MessageType] = [] {
        didSet {
            newChatAlert.isHidden = true
        }
    }
    private var editingMessageID: String?
    private var deleteForAll: [MessageType] = []
    private var deleteForSender: [MessageType] = []
    
    private let formatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      return formatter
    }()
    
    private var isPollingActive = false
    
    // MARK: - Initialization
    init(interactor: ChatBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        messagesCollectionView.register(EmptyCell.self, forCellWithReuseIdentifier: "EmptyCell")
        messagesCollectionView.register(MessageMenuButtonCell.self)
        super.viewDidLoad()
        interactor.loadFirstMessages { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let messages):
                    self.handleMessages(messages)
                case .failure(_):
                    break
                }
            }
        }
        configureUI()
        //        let tap1 = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        //        messagesCollectionView.addGestureRecognizer(tap1)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        newChatAlert.addGestureRecognizer(tap2)
        interactor.passUserData()
    }
    
    private func handleMessages(_ updates: [MessageForKit]) {
        for update in updates {
            switch update.content {
            case .text(_):
                messages.append(update)
            case .file(_):
                break
            case .reaction(_):
                break
            case .textEdited(let editedContent):
                if let index = messages.firstIndex(where: {$0.messageId == String(editedContent.messageID)}) {
                    guard var message = messages[index] as? MessageForKit else { return }
                    message.isEdited = true
                    messages[index] = message
                    messagesCollectionView.reloadData()
                }
            case .deleted(let chatDeletedUpdateContent):
                if chatDeletedUpdateContent.deleteMode == .DeleteModeForAll {
                    deleteForAll.append(update)
                } else {
                    deleteForSender.append(update)
                }
            }
        }
        deleteForAll(deleteForAll)
        deleteForSender(deleteForSender)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: false)
    }
    
    private func deleteForAll(_ messagesToDelete: [MessageType]) {
        let messagesToDelete: [String] = messagesToDelete.compactMap { message in
            if case .custom(let customData) = message.kind, let deleteKind = customData as? DeleteKind {
                return String(deleteKind.deleteMessageID)
            }
            return nil
        }
        
        messages = messages.filter { message in
            if let m = message as? MessageForKit {
                return !messagesToDelete.contains(m.messageId)
            }
            return true
        }
    }
    
    private func deleteForSender(_ messagesToDelete: [MessageType]) {
        let messagesToDelete: [String] = messagesToDelete.compactMap { message in
            if case .custom(let customData) = message.kind, let deleteKind = customData as? DeleteKind {
                if message.sender.senderId == curUser.senderId {
                    return String(deleteKind.deleteMessageID)
                }
            }
            return nil
        }
        
        messages = messages.filter { message in
            if let m = message as? MessageForKit {
                return !messagesToDelete.contains(m.messageId)
            }
            return true
        }
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
//    }
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//
//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
//    }
    
    // MARK: - Changing image color
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            guard let text = nicknameLabel.text else { return }
            let image = UIProfilePhoto(text, Constants.navigationItemHeight, Constants.borderWidth).getPhoto()
            iconImageView.image = image
        }
    }
    
    // MARK: - Public Methods
    func configureWithData(_ chatData: ChatsModels.GeneralChatModel.ChatData?, _ userData: ProfileSettingsModels.ProfileUserData, _ isSecret: Bool, _ myID: UUID) {
        let color = UIColor.random()
        let image = UIImage.imageWithText(
            text: userData.name,
            size: CGSize(width: Constants.navigationItemHeight, height:  Constants.navigationItemHeight),
            color: color,
            borderWidth: Constants.borderWidth
        )
        iconImageView.image = image
        if let photoURL = userData.photo {
            iconImageView.image = ImageCacheManager.shared.getImage(for: photoURL as NSURL)
            iconImageView.layer.cornerRadius = Constants.cornerRadius
        }
        nicknameLabel.text = userData.name
        curUser = SenderPerson(senderId: myID.uuidString, displayName: userData.name)
        if let cd = chatData {
            if case .personal(let info) = cd.info {
                if let b = info.blockedBy {
                    if !b.isEmpty {
                        inputBarType = .custom(blockInputBar)
                    } else {
                        inputBarType = .custom(messageInputBar)
                    }
                } else {
                    inputBarType = .custom(messageInputBar)
                }
            }
        }
    }
    
    func changeInputBar(_ isBlocked: Bool) {
        if isBlocked {
            inputBarType = .custom(blockInputBar)
        } else {
            inputBarType = .custom(messageInputBar)
        }
    }
    
    func showSecretKeyFail() {
        let failAllert = UIAlertController(title: "Failed to save secret key", message: "Try to save in again in profile", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default)
        failAllert.addAction(ok)
    }

    
    // MARK: - UI Configuration
    private func configureUI() {
        configureBackground()
        configureBackButton()
        configureIconImageView()
        configureNicknameLabel()
        configureNewChatAlert()
        configureMessagesCollectionView()
        configureBlockInputBar()
        configureInputBar()
    }
    
    private func configureBackground() {
        if ThemeManager.shared.currentTheme == AppTheme.dark || (ThemeManager.shared.currentTheme == AppTheme.system && traitCollection.userInterfaceStyle == .dark) {
            view.backgroundColor = Colors.background
        } else {
            let colors = [
                UIColor(hex: "ffffff") ?? Colors.background,
                UIColor(hex: "ffffff") ?? Colors.background,
                UIColor(hex: "ffe3b4") ?? Colors.background,
                UIColor(hex: "ffc768") ?? Colors.background,
                UIColor(hex: "ffb09c") ?? Colors.background,
                UIColor(hex: "ffa9d3") ?? Colors.background,
                UIColor(hex: "ffc2e0") ?? Colors.background,
                UIColor(hex: "ffdeee") ?? Colors.background
            ]
            gradientView = ChatBackgroundGradientView(colors: colors)
            
            view.addSubview(gradientView)
            gradientView.pinTop(view, 0)
            gradientView.pinBottom(view, 0)
            gradientView.pinLeft(view, 0)
            gradientView.pinRight(view, 0)
            
            view.sendSubviewToBack(gradientView)
        }
    }
    
    private func configureBackButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: Constants.arrowName), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem?.tintColor = Colors.text
        
        // Adding returning to previous screen with swipe.
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(backButtonPressed))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    private func configureIconImageView() {
        view.addSubview(iconImageView)
        iconImageView.layer.cornerRadius = Constants.cornerRadius
        iconImageView.clipsToBounds = true
        iconImageView.setWidth(Constants.navigationItemHeight)
        iconImageView.setHeight(Constants.navigationItemHeight)
        addTapGesture(to: iconImageView)
        
        let barButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = barButtonItem
    }
    
    private func configureNicknameLabel() {
        view.addSubview(nicknameLabel)
        nicknameLabel.textAlignment = .center
        nicknameLabel.font = Fonts.systemSB20
        nicknameLabel.textColor = Colors.text
        navigationItem.titleView = nicknameLabel
        addTapGesture(to: nicknameLabel)
    }
    
    private func addTapGesture(to view: UIView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTitleTap))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
    }
    
    
    private func configureNewChatAlert() {
        newChatAlert.configure(title: LocalizationManager.shared.localizedString(for: "alert_chat_title"),
                               message: LocalizationManager.shared.localizedString(for: "alert_chat"))
        view.addSubview(newChatAlert)
        newChatAlert.pinCenterX(view)
        newChatAlert.pinCenterY(view)
        newChatAlert.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8).isActive = true
        newChatAlert.isHidden = true // нужно придумать как исправить все баги
    }
    
    private func configureMessagesCollectionView() {
        messagesCollectionView.backgroundColor = .clear
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        scrollsToLastItemOnKeyboardBeginsEditing = true // default false
        maintainPositionOnInputBarHeightChanged = true // default false
        messageInputBar.delegate = self
        messagesCollectionView.isUserInteractionEnabled = true
        messagesCollectionView.messageCellDelegate = self
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
            layout
              .setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(
                textAlignment: .right,
                textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
            layout
              .setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(
                textAlignment: .right,
                textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
            layout
              .setMessageIncomingMessageTopLabelAlignment(LabelAlignment(
                textAlignment: .left,
                textInsets: UIEdgeInsets(top: 0, left: 18, bottom: 17.5, right: 0)))
        }
    }
    
    private func configureInputBar() {
        messageInputBar = CameraInputBarAccessoryView()
        messageInputBar.delegate = self
        messageInputBar.inputTextView.tintColor = .blue
        messageInputBar.sendButton.setTitleColor(.blue, for: .normal)
        messageInputBar.sendButton.setTitleColor(
            UIColor.blue.withAlphaComponent(0.3),
            for: .highlighted)
        
        messageInputBar.isTranslucent = true
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.inputTextView.tintColor = .blue
        messageInputBar.inputTextView.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
        messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.layer.borderColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1).cgColor
        messageInputBar.inputTextView.layer.borderWidth = 1
        messageInputBar.inputTextView.layer.cornerRadius = 16
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        configureInputBarItems()
        inputBarType = .custom(messageInputBar)
    }
    
    private func configureInputBarItems() {
        messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.sendButton.imageView?.backgroundColor = UIColor(white: 0.85, alpha: 1)
        messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        messageInputBar.sendButton.setSize(CGSize(width: 36, height: 36), animated: false)
        messageInputBar.sendButton.image = #imageLiteral(resourceName: "ic_up")
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.imageView?.layer.cornerRadius = 16
        let charCountButton = InputBarButtonItem()
            .configure {
                $0.title = "0/2000"
                $0.contentHorizontalAlignment = .right
                $0.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
                $0.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
                $0.setSize(CGSize(width: 50, height: 25), animated: false)
            }.onTextViewDidChange { item, textView in
                item.title = "\(textView.text.count)/2000"
                let isOverLimit = textView.text.count > 2000
                item.inputBarAccessoryView?
                    .shouldManageSendButtonEnabledState = !isOverLimit // Disable automated management when over limit
                if isOverLimit {
                    item.inputBarAccessoryView?.sendButton.isEnabled = false
                }
                let color = isOverLimit ? .red : UIColor(white: 0.6, alpha: 1)
                item.setTitleColor(color, for: .normal)
            }
        let bottomItems = [.flexibleSpace, charCountButton]
        
        configureInputBarPadding()
        
        messageInputBar.setStackViewItems(bottomItems, forStack: .bottom, animated: false)
        
        messageInputBar.sendButton
            .onEnabled { item in
                UIView.animate(withDuration: 0.3, animations: {
                    item.imageView?.backgroundColor = .blue
                })
            }.onDisabled { item in
                UIView.animate(withDuration: 0.3, animations: {
                    item.imageView?.backgroundColor = UIColor(white: 0.85, alpha: 1)
                })
            }
    }
    private func configureInputBarPadding() {
        // Entire InputBar padding
        messageInputBar.padding.bottom = 8
        
        // or MiddleContentView padding
        messageInputBar.middleContentViewPadding.right = -38
        
        // or InputTextView padding
        messageInputBar.inputTextView.textContainerInset.bottom = 8
    }
    
    private func configureBlockInputBar() {
        view.addSubview(blockInputBar)
        blockInputBar.backgroundColor = .secondarySystemBackground
        let customLabel = UILabel()
        customLabel.translatesAutoresizingMaskIntoConstraints = false
        customLabel.font = .preferredFont(forTextStyle: .headline)
        customLabel.textAlignment = .center
        customLabel.text = "This chat is read only."
        customLabel.textColor = .primaryColor
        blockInputBar.addSubview(customLabel)
        
        customLabel.pinTop(blockInputBar.topAnchor, 16)
        customLabel.pinBottom(blockInputBar.safeAreaLayoutGuide.bottomAnchor, 16)
        customLabel.pinLeft(blockInputBar.leadingAnchor, 0)
        customLabel.pinRight(blockInputBar.trailingAnchor, 0)
        inputBarType = .custom(blockInputBar)
    }
    
    private func makeButton(named: String) -> InputBarButtonItem {
        InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(10)
                $0.image = UIImage(named: named)?.withRenderingMode(.alwaysTemplate)
                $0.setSize(CGSize(width: 25, height: 25), animated: false)
                $0.tintColor = UIColor(white: 0.8, alpha: 1)
            }.onSelected {
                $0.tintColor = .blue
            }.onDeselected {
                $0.tintColor = UIColor(white: 0.8, alpha: 1)
            }.onTouchUpInside {
                print("Item Tapped")
                let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let action = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                actionSheet.addAction(action)
                if let popoverPresentationController = actionSheet.popoverPresentationController {
                    popoverPresentationController.sourceView = $0
                    popoverPresentationController.sourceRect = $0.frame
                }
                self.navigationController?.present(actionSheet, animated: true, completion: nil)
            }
    }
    
    private func insertPhoto(_ message: MessageType) {
        messages.append(message)
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messages.count - 1])
            if messages.count >= 2 {
                messagesCollectionView.reloadSections([messages.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        })
    }
    
    func isLastSectionVisible() -> Bool {
        guard !messages.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section - 1].sender.senderId
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messages.count else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section + 1].sender.senderId
    }
    
    private func showEmptyDisclaimer() {
        let disclaimer = UIAlertController(title: "You input empty key", message: "Try input key again", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default)
        disclaimer.addAction(ok)
        self.present(disclaimer, animated: true)
    }
    
    @objc private func handleTitleTap() {
        interactor.routeToProfile()
    }
    
    // MARK: - Actions
    @objc private func backButtonPressed() {
        interactor.routeBack()
    }
    
    @objc private func attachmentButtonTapped() {
        print("Attachment button tapped")
    }
    
    @objc private func dismissKeyboard() {
        print("foo")
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        let keyboardHeight = keyboardFrame.height

        if let buttonFrame = newChatAlert.superview?.convert(newChatAlert.frame, to: nil) {
            let bottomY = buttonFrame.maxY
            let screenHeight = UIScreen.main.bounds.height
            let inputBarSizeY = messageInputBar.frame.height
            if bottomY + inputBarSizeY > screenHeight - keyboardHeight {
                let overlap = bottomY + inputBarSizeY - (screenHeight - keyboardHeight)
                self.view.frame.origin.y -= overlap + Constants.extraKeyboardIndent
            }
        }
    }
    
    @objc private func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}

extension ChatViewController: MessagesDataSource {
    
    var currentSender: SenderType {
        return curUser
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func customCell(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        if case .custom(let custom) = message.kind {
            if custom is DeleteKind {
                return messagesCollectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCell", for: indexPath)
            }
        }
        return UICollectionViewCell() // будет ошибка но в этот кейс не зайдет
    }
    
    func customCellSizeCalculator(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator {
        return HiddenMessageSizeCalculator(layout: messagesCollectionView.messagesCollectionViewFlowLayout)
    }
}

extension ChatViewController: MessagesLayoutDelegate, MessagesDisplayDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
    }
    
    func textColor(for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> UIColor {
      isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    
    func backgroundColor(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message)
        ? UIColor(red: 0.25, green: 0.44, blue: 0.89, alpha: 1.0)
        : UIColor.systemGray5 
    }
    
    func messageBottomLabelAttributedText(for message: any MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        guard let message = message as? MessageStatusProtocol else { return nil}
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let dateString = dateFormatter.string(from: message.sentDate)
        
        let attributedString = NSMutableAttributedString(string: dateString)
        
        if message.sender.senderId == curUser.senderId {
            let statusText: String
            switch message.status {
            case .read:  statusText = " • read"
            case .sent: statusText = " • sent"
            case .error: statusText = " • failed ❗"
            case .edited: statusText = " • edited"
            case .sending: statusText = " • sending"
            }
            attributedString.append(NSAttributedString(string: statusText))
        }
        
        if message.isEdited {
            attributedString.append(NSAttributedString(string: " • edited"))
        }
        
        let baseColor: UIColor = (message.status == .error) ? .systemRed : .lightGray
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: baseColor
        ]
        attributedString.addAttributes(attributes, range: NSRange(location: 0, length: attributedString.length))
        
        return attributedString
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in _: MessagesCollectionView) -> MessageStyle {
        let tail: MessageStyle.TailStyle = .pointedEdge
        if isFromCurrentSender(message: message) {
            return MessageStyle.bubbleTail(.bottomRight, tail)
        } else {
            return MessageStyle.bubbleTail(.bottomLeft, tail)
        }
    }
    
    func cellTopLabelHeight(for message : MessageType, at indexPath: IndexPath, in _: MessagesCollectionView) -> CGFloat {
        if shouldShowDateLabel(for: message, at: indexPath) {
            return 18
        }
        return 0
    }

    func cellBottomLabelHeight(for _: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> CGFloat {
      0
    }

    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in _: MessagesCollectionView) -> CGFloat {
        if isFromCurrentSender(message: message) {
            return !isPreviousMessageSameSender(at: indexPath) ? 20 : 0
        } else {
            return !isPreviousMessageSameSender(at: indexPath) ? (20) : 0
        }
    }

    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in _: MessagesCollectionView) -> CGFloat {
        (!isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message)) ? 16 : 10
        
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if shouldShowDateLabel(for: message, at: indexPath) {
            return NSAttributedString(
                string: MessageKitDateFormatter.shared.string(from: message.sentDate),
                attributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                    NSAttributedString.Key.foregroundColor: UIColor.darkGray,
                ])
        }
        return nil
    }
    
    func shouldShowDateLabel(for message: MessageType, at indexPath: IndexPath) -> Bool {
        guard indexPath.section > 0 else { return true }
        
        let previousMessage = messages[indexPath.section - 1]
        
        return !Calendar.current.isDate(message.sentDate, inSameDayAs: previousMessage.sentDate)
    }

    func cellBottomLabelAttributedText(for _: MessageType, at _: IndexPath) -> NSAttributedString? {
        nil
    }
    

    func messageTopLabelAttributedText(for message: MessageType, at _: IndexPath) -> NSAttributedString? {
      nil
    }
    
    func messageBottomLabelAlignment(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment? {
        if isFromCurrentSender(message: message) {
            return LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16))
        } else {
            return LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0))
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        let button = UIButton(type: .system)
        cell.contentView.addSubview(button)
        button.frame = cell.bounds
        button.showsMenuAsPrimaryAction = true
        
        let subMenu = UIMenu(title: "Delete", children: [
            UIAction(title: "For both") { [weak self] _ in
                guard let self = self else { return }
                guard let deleteID = Int64(message.messageId) else { return }
                self.interactor.deleteMessage(deleteID, .DeleteModeForAll) { result in
                    DispatchQueue.main.async {
                        if result {
                            guard let index = self.messages.firstIndex(where: { $0.messageId == message.messageId }) else {
                                return
                            }
                            self.messages.remove(at: index)
                            self.messagesCollectionView.performBatchUpdates({
                                self.messagesCollectionView.deleteSections(IndexSet(integer: index))
                            }, completion: nil)
                            
                            if let cell = self.messagesCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) {
                                UIView.animate(withDuration: 0.25) {
                                    cell.alpha = 0
                                    cell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                                }
                            }
                        }
                    }
                }
            },
            UIAction(title: "For me") { [weak self] _ in
                guard let self = self else { return }
                guard let deleteID = Int64(message.messageId) else { return }
                self.interactor.deleteMessage(deleteID, .DeleteModeForSender) { result in
                    DispatchQueue.main.async {
                        if result {
                            guard let index = self.messages.firstIndex(where: { $0.messageId == message.messageId }) else {
                                return
                            }
                            self.messages.remove(at: index)
                            self.messagesCollectionView.performBatchUpdates({
                                self.messagesCollectionView.deleteSections(IndexSet(integer: index))
                            }, completion: nil)
                            
                            if let cell = self.messagesCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) {
                                UIView.animate(withDuration: 0.25) {
                                    cell.alpha = 0
                                    cell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                                }
                            }
                        }
                    }
                }
            }
        ])
        
        button.menu = UIMenu(children: [
            subMenu,
            UIAction(title: "Edit message") { [weak self] _ in
                guard let indexPath = self?.messagesCollectionView.indexPath(for: cell) else { return }
                let message = self?.messages[indexPath.section]
                if case .text(let text) = message?.kind {
                    self?.messageInputBar.inputTextView.text = text
                    self?.editingMessageID = message?.messageId
                    self?.messageInputBar.inputTextView.becomeFirstResponder()
                }
            }
        ])
        button.sendActions(for: .menuActionTriggered)
    }
}

extension ChatViewController: CameraInputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        if let messageID = editingMessageID {
            guard let index = messages.firstIndex(where: { $0.messageId == messageID}) else { return }
            let oldMessageToEdit = messages[index]
            
            if case .text(let oldText) = oldMessageToEdit.kind {
                if text == oldText {
                    messagesCollectionView.reloadData()
                } else {
                    let textMessage = OutgoingMessage(
                        sender: curUser,
                        messageId: messageID,
                        sentDate: oldMessageToEdit.sentDate,
                        kind: .text(text),
                        isEdited: true,
                        status: .sending,
                        text: text,
                        replyTo: nil
                    )
                    
                    messages[index] = textMessage
                    
                    self.messagesCollectionView.performBatchUpdates({
                        messagesCollectionView.reloadSections(IndexSet(integer: index))
                    }, completion: nil)
                    
                    inputBar.inputTextView.text = ""
                    
                    interactor.editTextMessage(Int64(messageID) ?? 0, text) { [weak self] isEdited in
                        DispatchQueue.main.async {
                            guard let self = self else { return }
                            if let index = self.messages.firstIndex(where: {$0.messageId == messageID}) {
                                let editedMessage = self.messages[index]
                                guard var editedMessage = editedMessage as? OutgoingMessage else { return }
                                editedMessage.status = isEdited ? .sent : .error
                                editedMessage.isEdited = isEdited ? true : false
                                self.messages[index] = isEdited ? editedMessage : oldMessageToEdit
                                self.messagesCollectionView.reloadSections([index])
                            }
                            self.editingMessageID = nil
                        }
                    }
                }
            }
            
        } else {
            let outgoingMessage = OutgoingMessage(
                sender: curUser,
                messageId: UUID().uuidString,
                sentDate: Date(),
                kind: .text(text),
                isEdited: false,
                status: .sending,
                text: text,
                replyTo: nil
            )
            newChatAlert.isHidden = true
            messages.append(outgoingMessage)
            inputBar.inputTextView.text = ""
            messagesCollectionView.insertSections([messages.count - 1])
            messagesCollectionView.reloadData()
            interactor.sendTextMessage(text) { [weak self] isSent in
                guard let self = self else { return }
                if let index = self.messages.firstIndex(where: { $0.messageId == outgoingMessage.messageId }) {
                    if var message = self.messages[index] as? OutgoingMessage {
                        message.status = isSent ? .sent : .error
                        self.messages[index] = message
                        self.messagesCollectionView.reloadSections([index])
                    }
                }
            }
        }
        messagesCollectionView.scrollToLastItem(animated: true)
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith attachments: [AttachmentManager.Attachment]) {
        newChatAlert.isHidden = true
        for item in attachments {
            if case .image(let image) = item {
                self.sendImageMessage(photo: image)
            }
        }
        inputBar.invalidatePlugins()
    }
    
    func sendImageMessage(photo: UIImage) {
        let imageMediaItem = ImageMediaItem(image: photo)
        let photoMessage = PhotoMessage(
            sender: curUser,
            messageId: UUID().uuidString,
            sentDate: Date(),
            media: imageMediaItem
        )
        insertPhoto(photoMessage)
    }
}

extension UIColor {
    static let primaryColor = UIColor(red: 69 / 255, green: 193 / 255, blue: 89 / 255, alpha: 1)
}

final class EmptyCell: UICollectionViewCell {}

class MessageMenuButtonCell: MessageContentCell {
    var messageButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(messageButton)
    }
}
