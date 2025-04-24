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
import AVKit

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
    
    private var curUser = SenderPerson(senderId: "", displayName: "")
    private var messages: [MessageType] = [] {
        didSet {
            messagesCollectionView.reloadData()
        }
    }
    
    private var deleteForAll: [GroupMessageDelete] = []
    private var deleteForSender: [GroupMessageDelete] = []
    
    private var replyPreviewView: ReplyPreviewView?
    private var repliedMessage: MessageType?
    
    private var editingMessageID: String?
    private var editingMessage: String?
    
    private let formatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      return formatter
    }()
    
    private let attachmentManager: AttachmentManager = AttachmentManager()
    
    // MARK: - Initialization
    init(interactor: ChatBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell
    {
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)

        switch message.kind {
        case .text:
            if message is GroupFileMessage || message is OutgoingFileMessage {
                let cell = messagesCollectionView.dequeueReusableCell(FileMessageCell.self, for: indexPath)
                cell.cellDelegate = self
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            }
            if message is GroupTextMessage || message is GroupOutgoingMessage {
                let cell = messagesCollectionView.dequeueReusableCell(ReactionTextMessageCell.self, for: indexPath)
                cell.cellDelegate = self
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            }
            if message is EncryptedMessage {
                let cell = messagesCollectionView.dequeueReusableCell(EncryptedCell.self, for: indexPath)
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            }
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        case .photo, .video:
            let cell = messagesCollectionView.dequeueReusableCell(CustomMediaMessageCell.self, for: indexPath)
            cell.cellDelegate = self
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
        default:
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.register(ReactionTextMessageCell.self)
        messagesCollectionView.register(CustomMediaMessageCell.self)
        messagesCollectionView.register(FileMessageCell.self)
        messagesCollectionView.register(EncryptedCell.self)
        addSecretKeyObserver()
        loadFirstMessages()
        configureUI()
        interactor.passUserData()
    }
    
    private func addSecretKeyObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSecretKeyUpdate),
            name: .secretKeyUpdated,
            object: nil
        )
    }
    
    private func loadFirstMessages() {
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
    }
    
    private func handleMessages(_ updates: [MessageType]) {
        for update in updates {
            if var update = update as? GroupTextMessage {
                if let replyToID = update.replyToID {
                    guard let index = messages.firstIndex(where: {$0.messageId == String(replyToID)}) else { return }
                    if let repliedMessage = messages[index] as? GroupTextMessage {
                        update.replyTo = repliedMessage.text
                        print(repliedMessage.text)
                    }
                }
                messages.append(update)
            }
            if let update = update as? GroupTextMessageEdited {
                if let index = messages.firstIndex(where: {$0.messageId == String(update.oldTextUpdateID)}) {
                    guard var message = messages[index] as? GroupTextMessage else { return }
                    message.isEdited = true
                    message.editedMessage = update.newText
                    message.text = update.newText
                    messages[index] = message
                }
            }
            if let update = update as? GroupFileMessage {
                messages.append(update)
            }
            if let update = update as? GroupReaction {
                if let index = messages.firstIndex(where: { $0.messageId == String(update.onMessageID)}) {
                    if var message = messages[index] as? GroupTextMessage {
                        message.reactions?.updateValue(update.reaction, forKey: Int64(update.messageId) ?? 0)
                    }
                    if var message = messages[index] as? GroupFileMessage {
                        message.reactions?.updateValue(update.reaction, forKey: Int64(update.messageId) ?? 0)
                    }
                }
            }
            if let update = update as? GroupMessageDelete {
                if update.deleteMode == .DeleteModeForAll {
                    deleteForAll.append(update)
                } else {
                    deleteForSender.append(update)
                }
            }
            if let update = update as? EncryptedMessage {
                messages.append(update)
            }
        }
        
        deleteForAll(deleteForAll)
        deleteForSender(deleteForSender)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: false)
    }
    
    private func deleteForAll(_ messagesToDelete: [GroupMessageDelete]) {
        let deleteIDs = Set(messagesToDelete.map { String($0.deletedMessageID) })
        messages = messages.filter { !deleteIDs.contains($0.messageId)}
    }
    
    private func deleteForSender(_ messagesToDelete: [GroupMessageDelete]) {
        let deleteMessageDict = Dictionary(
            uniqueKeysWithValues: messagesToDelete.map {
                (String($0.deletedMessageID), $0.sender.senderId)
            }
        )
        messages = messages.filter { deleteMessageDict[$0.messageId] != $0.sender.senderId }
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
        if isSecret {
            interactor.checkForSecretKey()
        }
    }
    
    func changeInputBar(_ isBlocked: Bool) {
        if isBlocked {
            inputBarType = .custom(blockInputBar)
        } else {
            inputBarType = .custom(messageInputBar)
        }
    }
    
    func showSecretKeyAlert() {
        let alert = UIAlertController(title: "New encryption key", message: "Input new encryption key", preferredStyle: .alert)
        
        alert.addTextField {tf in
            tf.placeholder = "Input key..."
        }
        
        let ok = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if let key = alert.textFields?.first?.text {
                if key != "" {
                    self?.interactor.saveSecretKey(key)
                } else {
                    self?.showSecretKeyAlert()
                }
            }
        }
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
    func showSecretKeyFail() {
        let failAllert = UIAlertController(title: LocalizationManager.shared.localizedString(for: "fail_to_save_secret_key"), message: LocalizationManager.shared.localizedString(for: "try_again"), preferredStyle: .alert)
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
            layout.setMessageIncomingAvatarSize(.zero)
            layout.setMessageOutgoingAvatarSize(.zero)
        }
    }
    
    private func configureInputBar() {
        messageInputBar = CameraInputBarAccessoryView()
        messageInputBar.delegate = self
        
        messageInputBar.isTranslucent = true
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.inputTextView.backgroundColor = Colors.inputBar
        messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.layer.borderColor = Colors.inputBarBorder.cgColor
        messageInputBar.inputTextView.layer.borderWidth = 1
        messageInputBar.inputTextView.layer.cornerRadius = 16
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        configureInputBarItems()
        inputBarType = .custom(messageInputBar)
    }
    
    private func configureInputBarItems() {
        messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.sendButton.imageView?.backgroundColor = Colors.disableButton
        messageInputBar.sendButton.setSize(CGSize(width: 36, height: 36), animated: false)
        messageInputBar.sendButton.image = #imageLiteral(resourceName: "ic_up")
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.imageView?.layer.cornerRadius = 18
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
                    item.imageView?.backgroundColor = Colors.disableButton
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
    // MARK: - Sending updates
    private func sendTextMessage(_ inputBar: InputBarAccessoryView, _ text: String) {
        let outgoingMessage = GroupOutgoingMessage(
            sender: curUser,
            messageId: UUID().uuidString,
            sentDate: Date(),
            kind: .text(text),
            replyTo: nil,
            status: .sending
        )
        
        messages.append(outgoingMessage)
        inputBar.inputTextView.text = ""
        messagesCollectionView.insertSections([messages.count - 1])
        messagesCollectionView.reloadData()
        
        interactor.sendTextMessage(text, nil) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self,
                      let index = self.messages.firstIndex(where: { $0.messageId == outgoingMessage.messageId }) else { return }
                
                switch result {
                case .success(let data):
                    var textMessage = self.interactor.mapToTextMessage(data)
                    textMessage.status = .sent
                    self.messages[index] = textMessage
                    self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                    self.messagesCollectionView.scrollToLastItem(animated: false)
                    print(data)
                case .failure(let failure):
                    print(failure)
                }
            }
        }
    }
    
    private func sendEditRequest(_ inputBar: InputBarAccessoryView, _ text: String) {
        guard let index = messages.firstIndex(where: { $0.messageId == editingMessageID}),
              let editingMessageID = editingMessageID
        else { return }
        if var message = messages[index] as? GroupTextMessage {
            if text == message.text {
                messagesCollectionView.reloadData()
            } else {
                message.text = text
                message.status = .sending
                messages[index] = message
                self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                inputBar.inputTextView.text = ""
                
                removeReplyPreview(.edit)
                
                interactor.editTextMessage(Int64(editingMessageID) ?? 0, text) { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        switch result {
                        case .success(let data):
                            let editedText = self.interactor.mapToTextMessage(data)
                            if let index = self.messages.firstIndex(where: {$0.messageId == editingMessageID}) {
                                guard var message = self.messages[index] as? GroupTextMessage else { return }
                                message.isEdited = true
                                message.editedMessage = text
                                message.text = text
                                message.status = .sent
                                self.messages[index] = message
                                self.messagesCollectionView.reloadData()
                                self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                            }
                            print(data)
                        case .failure(let failure):
                            print(failure)
                        }
                        self.editingMessage = nil
                        self.editingMessageID = nil
                    }
                }
            }
        }
    }
    
    private func sendReplyRequest(_ inputBar: InputBarAccessoryView, _ text: String) {
        guard let _ = replyPreviewView,
              let repliedMessage = repliedMessage else { return }
        
        let outgoingMessage = GroupOutgoingMessage(
            sender: curUser,
            messageId: UUID().uuidString,
            sentDate: Date(),
            kind: .text(text),
            replyTo: repliedMessage,
            status: .sending
        )
        messages.append(outgoingMessage)
        inputBar.inputTextView.text = ""
        messagesCollectionView.insertSections([messages.count - 1])
        messagesCollectionView.reloadData()
        interactor.sendTextMessage(text, Int64(repliedMessage.messageId) ?? 0) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self,
                      let index = self.messages.firstIndex(where: { $0.messageId == outgoingMessage.messageId }) else { return }
                switch result {
                case .success(let data):
                    var textMessage = self.interactor.mapToTextMessage(data)
                    textMessage.status = .sent
                    if case .text(let text) = repliedMessage.kind {
                        textMessage.replyTo = text
                    }
                    self.messages[index] = textMessage
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                    self.messagesCollectionView.scrollToLastItem(animated: false)
                    print(data)
                case .failure(let failure):
                    print(failure)
                }
                self.messageInputBar.topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                self.messageInputBar.setNeedsLayout()
                self.replyPreviewView = nil
                self.repliedMessage = nil
            }
        }
    }
    
    private func replyToMessage(_ messageIndexPath: IndexPath) {
        let message = messages[messageIndexPath.section]
        showReplyPreview(for: message, type: .reply)
    }
    
    private func editMessage(_ messageIndexPath: IndexPath) {
        let message = messages[messageIndexPath.section]
        if let message = message as? GroupTextMessage {
            messageInputBar.inputTextView.text = message.text
            messageInputBar.inputTextView.becomeFirstResponder()
            editingMessageID = message.messageId
            editingMessage = message.text
            showReplyPreview(for: message, type: .edit)
            messagesCollectionView.scrollToLastItem(animated: true)
        }
    }
    
    private func deleteMessage(_ messageIndexPath: IndexPath, mode: DeleteMode) {
        let deletedMessage = messages[messageIndexPath.section]
        self.messages.remove(at: messageIndexPath.section)
        self.messagesCollectionView.performBatchUpdates({
            self.messagesCollectionView.deleteSections(IndexSet(integer: messageIndexPath.section))
        }, completion: nil)
        
        if let cell = self.messagesCollectionView.cellForItem(at: IndexPath(item: 0, section: messageIndexPath.section)) {
            UIView.animate(withDuration: 0.25) {
                cell.alpha = 0
                cell.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
        }
        self.interactor.deleteMessage(Int64(deletedMessage.messageId) ?? 0, mode) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self,
                      let _ = self.messages.firstIndex(where: { $0.messageId == deletedMessage.messageId }) else { return }
                switch result {
                case .success(let data):
                    print(data)
                case .failure(let failure):
                    self.messages.append(deletedMessage)
                    self.messagesCollectionView.insertSections([self.messages.count - 1])
                    self.messagesCollectionView.reloadData()
                    print(failure)
                }
            }
        }
    }
    
    func sendReaction(_ emoji: String, _ onMessage: Int64) {
        if let messageIndex = messages.firstIndex(where: {$0.messageId == String(onMessage)}) {
            guard var message = messages[messageIndex] as? GroupMessageWithReactions else { return }
            let newKey = (message.reactions?.keys.max() ?? 0) + 1 // чтобы ключ гарантированно был новый
            message.reactions?.updateValue(emoji, forKey: newKey)
            message.curUserPickedReaction?.append(emoji)
            if let message = message as? GroupTextMessage {
                messages[messageIndex] = message
                messagesCollectionView.reloadData()
            }
            if let message = message as? GroupFileMessage {
                messages[messageIndex] = message
                messagesCollectionView.reloadData()
            }
            
            let emoji = mapEmoji(emoji)
            interactor.sendReaction(emoji, onMessage) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_): break
                    case .failure(let failure):
                        print(failure)
                    }
                }
            }
        }
    }
    
    func deleteReaction(_ reactionID: Int64) {
        messages.forEach { message in
            if var newMessage = message as? GroupMessageWithReactions {
                newMessage.reactions?.removeValue(forKey: reactionID)
                if let index = messages.firstIndex(where: {$0.messageId == message.messageId}) {
                    if let m = newMessage as? GroupTextMessage {
                        messages[index] = m
                        messagesCollectionView.reloadData()
                    }
                    if let m = newMessage as? GroupFileMessage {
                        messages[index] = m
                        messagesCollectionView.reloadData()
                    }
                    
                    interactor.deleteReaction(reactionID) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(_): break
                            case .failure(let failure):
                                print(failure)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func mapEmoji(_ emoji: String) -> String {
        switch emoji {
        case "❤️": return "heart"
        case "👍": return "like"
        case "⚡️": return "thunder"
        case "😭": return "cry"
        case "👎": return "dislike"
        case "🐝": return "bzZZ"
        default: return "unknown"
        }
    }
    
    private func showEmptyDisclaimer() {
        let disclaimer = UIAlertController(title: LocalizationManager.shared.localizedString(for: "you_input_empty_key"), message: LocalizationManager.shared.localizedString(for: "try_again"), preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default)
        disclaimer.addAction(ok)
        self.present(disclaimer, animated: true)
    }
    
    private func showReplyPreview(for message: MessageType, type: ReplyType) {
        replyPreviewView?.removeFromSuperview()
        
        let preview = ReplyPreviewView(message: message, type: type)
        preview.onClose = { [weak self] in
            self?.removeReplyPreview(type)
        }
        
        messageInputBar.topStackView.addArrangedSubview(preview)
        messageInputBar.topStackView.layoutIfNeeded()
        
        messageInputBar.topStackView.becomeFirstResponder()
        
        replyPreviewView = preview
        repliedMessage = message
    }
    
    private func removeReplyPreview(_ type: ReplyType) {
        replyPreviewView?.removeFromSuperview()
        messageInputBar.topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        messageInputBar.setNeedsLayout()
        replyPreviewView = nil
        repliedMessage = nil
        editingMessage = nil
        if type == .edit {
            messageInputBar.inputTextView.text = ""
        }
    }
    //MARK: - File sendings
    private func sendPhoto(_ photo: UIImage) {
        var photoMessage = mapPhoto(photo)
        insertPhoto(photoMessage)
        interactor.uploadImage(photo) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self,
                      let index = self.messages.firstIndex(where: {$0.messageId == photoMessage.messageId}) else { return }
                switch result {
                case .success(let fileUpdate):
                    var fileMessage = self.interactor.mapToFileMessage(fileUpdate)
                    fileMessage.status = .sent
                    self.messages[index] = fileMessage
                    self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                    self.messagesCollectionView.scrollToLastItem(animated: false)
                    print(fileUpdate)
                case .failure(let failure):
                    photoMessage.status = .error
                    self.messages[index] = photoMessage
                    self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                    self.messagesCollectionView.scrollToLastItem(animated: false)
                    print(failure)
                }
            }
        }
    }
    
    private func sendVideo(_ videoURL: URL) {
        let thumbnail = generateThumbnail(for: videoURL)
        var videoMessage = mapVideo(videoURL, thumbnail.size)
        messages.append(videoMessage)
        messagesCollectionView.reloadData()
        interactor.uploadVideo(videoURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self,
                      let index = self.messages.firstIndex(where: {$0.messageId == videoMessage.messageId}) else { return }
                switch result {
                case .success(let fileUpdate):
                    var fileMessage = self.interactor.mapToFileMessage(fileUpdate)
                    fileMessage.status = .sent
                    self.messages[index] = fileMessage
                    self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                    self.messagesCollectionView.scrollToLastItem(animated: false)
                case .failure(let failure):
                    videoMessage.status = .error
                    self.messages[index] = videoMessage
                    self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                    self.messagesCollectionView.scrollToLastItem(animated: false)
                    print(failure)
                }
            }
        }
    }
    
    func sendFile(_ url: URL, _ mimeType: String?) {
        var fileMessage = mapFile(url)
        messages.append(fileMessage)
        messagesCollectionView.reloadData()
        interactor.uploadFile(url, mimeType) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self,
                      let index = self.messages.firstIndex(where: {$0.messageId == fileMessage.messageId}) else { return }
                switch result {
                case .success(let fileUpdate):
                    if case .fileContent(let fc) = fileUpdate.content {
                        FileCacheManager.shared.saveFile(fc.file.fileURL, fc.file.fileName, fc.file.mimeType)
                        { _ in}
                    }
                    var uploadedFileMessage = self.interactor.mapToFileMessage(fileUpdate)
                    uploadedFileMessage.status = .sent
                    self.messages[index] = uploadedFileMessage
                    self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                    self.messagesCollectionView.scrollToLastItem(animated: false)
                case .failure(let failure):
                    fileMessage.status = .error
                    self.messages[index] = fileMessage
                    self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                    self.messagesCollectionView.scrollToLastItem(animated: false)
                    print(failure)
                }
            }
        }
    }
    
    private func generateThumbnail(for videoURL: URL) -> UIImage {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let maxSize = CGSize(width: 200, height: 200)
        generator.maximumSize = maxSize
        
        do {
            let cgImage = try generator.copyCGImage(at: CMTime(value: 1, timescale: 60), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            let scaledImage = thumbnail.scaledToFit(maxSize: maxSize)
            return scaledImage
            
        } catch {
            return UIImage(systemName: "play.circle.fill")!
        }
    }
    
    private func mapPhoto(_ photo: UIImage) -> OutgoingPhotoMessage {
        return OutgoingPhotoMessage(
            sender: curUser,
            messageId: UUID().uuidString,
            sentDate: Date(),
            media: MockMediaItem(url: nil, image: photo, placeholderImage: UIImage(), size: CGSize(width: 200, height: 200)),
            status: .sending
        )
    }
    
    private func mapVideo(_ videoURL: URL, _ size: CGSize) -> OutgoingPhotoMessage {
        return OutgoingPhotoMessage(
            sender: curUser,
            messageId: UUID().uuidString,
            sentDate: Date(),
            media: MockMediaItem(url: videoURL, image: nil, placeholderImage: UIImage(systemName: "photo")!, size: size),
            status: .sending
        )
    }
    
    private func mapFile(_ fileURL: URL) -> OutgoingFileMessage {
        return OutgoingFileMessage(
            sender: curUser,
            messageId: UUID().uuidString,
            sentDate: Date(),
            kind: .text(fileURL.absoluteString),
            status: .sending
        )
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
    
    @objc func handleSecretKeyUpdate() {
        DispatchQueue.main.async {
            self.messages = []
            self.messagesCollectionView.reloadData()
            self.interactor.loadFirstMessages { [weak self] result in
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
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    func textCell(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell? {
        
        if case .text = message.kind {
            if message is GroupFileMessage || message is OutgoingFileMessage {
                let cell = messagesCollectionView.dequeueReusableCell(FileMessageCell.self, for: indexPath)
                cell.cellDelegate = self
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            }
            if message is GroupTextMessage || message is GroupOutgoingMessage {
                let cell = messagesCollectionView.dequeueReusableCell(ReactionTextMessageCell.self, for: indexPath)
                cell.cellDelegate = self
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            }
            if message is EncryptedMessage {
                let cell = messagesCollectionView.dequeueReusableCell(EncryptedCell.self, for: indexPath)
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            }
        }
        return TextMessageCell()
    }
    
    func photoCell(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell? {
        
        if case .photo = message.kind {
            let cell = messagesCollectionView.dequeueReusableCell(CustomMediaMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            cell.cellDelegate = self
            return cell
        }
        return MediaMessageCell()
    }
    
    func customCell(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        if case .custom = message.kind {
            let cell = messagesCollectionView.dequeueReusableCell(FileMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            cell.cellDelegate = self
            return cell
        }
        return UICollectionViewCell()
    }
}

extension ChatViewController: MessagesLayoutDelegate, MessagesDisplayDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
    }
    
    func textColor(for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> UIColor {
        if message is EncryptedMessage {
            return .red
        }
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    func backgroundColor(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message)
        ? UIColor(red: 0.25, green: 0.44, blue: 0.89, alpha: 1.0)
        : UIColor.systemGray5
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
    
    func cellBottomLabelAttributedText(for _: MessageType, at _: IndexPath) -> NSAttributedString? {
        nil
    }
    
    func shouldShowDateLabel(for message: MessageType, at indexPath: IndexPath) -> Bool {
        guard indexPath.section > 0 else { return true }
        
        let previousMessage = messages[indexPath.section - 1]
        
        return !Calendar.current.isDate(message.sentDate, inSameDayAs: previousMessage.sentDate)
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in _: MessagesCollectionView) -> CGFloat {
        if let message = message as? GroupMessageForwardedStatus {
            if message.isForwarded == true {
                return 10
            }
        }
        return 0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in _: MessagesCollectionView) -> CGFloat {
        if let message = message as? GroupTextMessage {
            if message.isEdited == true {
                return 12
            }
        }
        return 0
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if let message = message as? GroupMessageForwardedStatus {
            if message.isForwarded == true {
                return NSAttributedString(
                    string: "Forwarded",
                    attributes: [
                        NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                        NSAttributedString.Key.foregroundColor: UIColor.darkGray,
                    ]
                )
            }
        }
        return nil
    }
    
    func messageBottomLabelAttributedText(for message: any MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if let message = message as? GroupTextMessage {
            if message.isEdited == true {
                return NSAttributedString(
                    string: " • edited",
                    attributes: [
                        NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                        NSAttributedString.Key.foregroundColor: UIColor.darkGray,
                    ]
                )
            }
        }
        return nil
    }
    
    func messageBottomLabelAlignment(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment? {
        if isFromCurrentSender(message: message) {
            return LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 30))
        } else {
            return LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0))
        }
    }
    //MARK: - Size calculators
    func textCellSizeCalculator(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator? {
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            if case .text = message.kind {
                if message is GroupOutgoingMessage || message is GroupTextMessage {
                    return ReactionMessageSizeCalculator(layout: layout, isGroupChat: false)
                }
                if message is OutgoingFileMessage || message is GroupFileMessage {
                    return FileMessageCellSizeCalculator(layout: layout, isGroupChat: false)
                }
                if message is EncryptedMessage {
                    return EncryptedCellSizeCalculator(layout: layout, isGroupChat: false)
                }
            }
        }
        return nil
    }
    
    func photoCellSizeCalculator(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator? {
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            if case .photo = message.kind {
                return CustomMediaMessageSizeCalculator(layout: layout, isGroupChat: false)
            }
        }
        return nil
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              case .video(let mediaItem) = messages[indexPath.section].kind,
              let url = mediaItem.url else { return }

        let player = AVPlayer(url: url)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        present(playerVC, animated: true) {
            player.play()
        }
    }
}

extension ChatViewController: TextMessageEditMenuDelegate, FileMessageEditMenuDelegate {
    
    func didTapCopy(for message: IndexPath) {
        let message = messages[message.section]
        if let message = message as? GroupTextMessage {
            UIPasteboard.general.string = message.text
        }
        if let message = message as? GroupFileMessage {
            if let image = ImageCacheManager.shared.getImage(for: message.fileURL as NSURL) {
                UIPasteboard.general.image = image
            }
        }
    }
    
    func didTapReply(for message: IndexPath) {
        replyToMessage(message)
    }
    
    func didTapEdit(for message: IndexPath) {
        editMessage(message)
    }
    
    func didTapDelete(for message: IndexPath, mode: DeleteMode) {
        deleteMessage(message, mode: mode)
    }
    
    func didSelectReaction(_ emojiID: Int64?, _ emoji: String, for indexPath: IndexPath) {
        if let emojiID = emojiID {
            deleteReaction(emojiID)
        } else {
            let message = messages[indexPath.section]
            sendReaction(emoji, Int64(message.messageId) ?? 0)
        }
    }
    
    func didTapForwardText(for message: IndexPath) {
        if let message = messages[message.section] as? GroupTextMessage {
            interactor.forwardMessage(Int64(message.messageId) ?? 0, .text)
        }
    }
    
    func didTapForwardFile(for message: IndexPath) {
        if let message = messages[message.section] as? GroupFileMessage {
            interactor.forwardMessage(Int64(message.messageId) ?? 0, .file)
        }
    }
    
    func didTapReply(_ indexPath: IndexPath) {
        if let message = messages[indexPath.section] as? GroupTextMessage,
           let replyToID = message.replyToID {
            if let targetIndex = messages.firstIndex(where: {$0.messageId == String(replyToID)}) {
                let targetIndexPath = IndexPath(item: 0, section: targetIndex)
                messagesCollectionView.scrollToItem(at: targetIndexPath, at: .centeredVertically, animated: true)
            }
        }
    }
    
    func didTapLoad(for message: IndexPath) {
        let message = messages[message.section]
        if case .photo(let photo) = message.kind {
            guard let url = photo.url,
                  let image = ImageCacheManager.shared.getImage(for: url as NSURL) else { return }
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
        }
        if case .video(let video) = message.kind {
            guard let url = video.url else { return }
            handleVideoDownload(url)
        }
        if case .text(let stringURL) = message.kind {
            let components = stringURL.components(separatedBy: "#")
            guard let url = URL(string: components[0]) else { return }
            let fileName = components[1]
            handleFileDownload(url, fileName)
        }
    }
    
    private func handleVideoDownload(_ url: URL) {
        let pathExtension = url.pathExtension
        let fileName: String
        if pathExtension.isEmpty {
            fileName = UUID().uuidString + ".mp4"
        } else {
            fileName = url.lastPathComponent
        }
        
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let localURL = cacheDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: localURL.path) {
            DispatchQueue.main.async {
                UISaveVideoAtPathToSavedPhotosAlbum(localURL.path, self, #selector(self.saveError), nil)
            }
        } else {
            URLSession.shared.downloadTask(with: url) { tempURL, _, error in
                guard let tempURL = tempURL, error == nil else { return }
                
                do {
                    try FileManager.default.moveItem(at: tempURL, to: localURL)
                    DispatchQueue.main.async {
                        UISaveVideoAtPathToSavedPhotosAlbum(localURL.path, self, #selector(self.saveError), nil)
                    }
                } catch {
                    debugPrint("Failed to save \(error)")
                }
            }.resume()
        }
    }
    
    private func handleFileDownload(_ url: URL, _ fileName: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localURL = documentsDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: localURL.path) {
            showFileSavePrompt(for: localURL)
        } else {
            downloadFile(from: url, to: localURL) {
                DispatchQueue.main.async {
                    self.showFileSavePrompt(for: localURL)
                }
            }
        }
    }
    
    private func downloadFile(from remoteURL: URL, to localURL: URL, completion: @escaping () -> Void) {
        URLSession.shared.downloadTask(with: remoteURL) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else {
                print("Download error: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            
            do {
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                completion()
            } catch {
                print("File save error: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func showFileSavePrompt(for fileURL: URL) {
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if completed {
                print("File saved successfully")
            } else if let error = error {
                print("Error sharing file: \(error.localizedDescription)")
            }
        }
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
    
    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Failed to save image in galery: \(error.localizedDescription)")
        } else {
            print("Saved in galery")
        }
    }
}
//MARK: - CameraInputBarAccessoryViewDelegate
extension ChatViewController: CameraInputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        if editingMessage != nil {
            sendEditRequest(inputBar, text)
        } else if repliedMessage != nil {
            sendReplyRequest(inputBar, text)
        } else {
            sendTextMessage(inputBar, text)
        }
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith attachments: [AttachmentManager.Attachment]) {
        for attachment in attachments {
            if case .image(let image) = attachment {
                sendPhoto(image)
            }
            if case .url(let url) = attachment {
                let mimeType = url.pathExtension
                if !mimeType.contains("video") && !mimeType.contains("MOV") && !mimeType.contains("avi") && !mimeType.contains("mpeg") && !mimeType.contains("mpg") && !mimeType.contains("dvi") {
                    sendFile(url, mimeType)
                } else {
                    sendVideo(url)
                }
            }
        }
        inputBar.invalidatePlugins()
    }
    
    private func mimeTypeForURL(_ url: URL) -> String? {
        let fileExtension = url.pathExtension.lowercased()
        if #available(iOS 14.0, *) {
            return UTType(filenameExtension: fileExtension)?.preferredMIMEType
        } else {
            return nil
        }
    }
}

extension UIColor {
    static let primaryColor = UIColor(red: 69 / 255, green: 193 / 255, blue: 89 / 255, alpha: 1)
}

final class EmptyCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .red
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Notification.Name {
    static let secretKeyUpdated = Notification.Name("SecretKeyUpdated")
}
