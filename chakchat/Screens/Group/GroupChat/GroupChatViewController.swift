//
//  GroupChatViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit
import MessageKit
import InputBarAccessoryView

final class GroupChatViewController: MessagesViewController {
    
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
        static let outgoingAvatarOverlap: CGFloat = 17.5
    }
    
    // MARK: - Properties
    private let interactor: GroupChatBusinessLogic
    private let iconImageView: UIImageView = UIImageView()
    private let groupNameLabel: UILabel = UILabel()
    private let newChatAlert: UINewChatAlert = UINewChatAlert()
    private var gradientView: ChatBackgroundGradientView = ChatBackgroundGradientView()
    
    private var curUser: GroupSender = GroupSender(senderId: "", displayName: "", avatar: nil)
    private var messages: [MessageType] = []
    
    private var deleteForAll: [GroupMessageDelete] = []
    private var deleteForSender: [GroupMessageDelete] = []
    
    private var replyPreviewView: ReplyPreviewView?
    private var repliedMessage: MessageType?
    
    private var editingMessageID: String?
    private var editingMessage: String?
    
    // MARK: - Initialization
    init(interactor: GroupChatBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
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
        if case .text = message.kind {
            let cell = messagesCollectionView.dequeueReusableCell(ReactionTextMessageCell.self, for: indexPath)
            cell.cellDelegate = self
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.register(ReactionTextMessageCell.self)
        loadFirstMessages()
        configureUI()
        interactor.passChatData()
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
            if let update = update as? GroupTextMessage {
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
            if update is GroupFileMessage {
                // пока что пусто
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
    
    func configureWithData(_ chatData: ChatsModels.GeneralChatModel.ChatData) {
        if case .group(let groupInfo) = chatData.info {
            let color = UIColor.random()
            let image = UIImage.imageWithText(
                text: groupInfo.name,
                size: CGSize(width: Constants.navigationItemHeight, height:  Constants.navigationItemHeight),
                color: color,
                borderWidth: Constants.borderWidth
            )
            iconImageView.image = image
            if let photoURL = groupInfo.groupPhoto {
                iconImageView.image = ImageCacheManager.shared.getImage(for: photoURL as NSURL)
                iconImageView.layer.cornerRadius = Constants.cornerRadius
            }
            groupNameLabel.text = groupInfo.name
            
            curUser = GroupSender(senderId: groupInfo.admin.uuidString, displayName: "", avatar: nil)
        }
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        configureBackground()
        configureBackButton()
        configureIconImageView()
        configureNicknameLabel()
        //configureNewChatAlert()
        configureMessagesCollectionView()
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
        view.addSubview(groupNameLabel)
        groupNameLabel.textAlignment = .center
        groupNameLabel.font = Fonts.systemSB20
        groupNameLabel.textColor = Colors.text
        navigationItem.titleView = groupNameLabel
        addTapGesture(to: groupNameLabel)
    }
    
    private func configureNewChatAlert() {
        newChatAlert.configure(title: LocalizationManager.shared.localizedString(for: "alert_group_title"),
                               message: LocalizationManager.shared.localizedString(for: "alert_group"))
        view.addSubview(newChatAlert)
        
        newChatAlert.pinCenterX(view)
        newChatAlert.pinCenterY(view)
        newChatAlert.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8).isActive = true
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
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.sectionInset = UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8)
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?
            .setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(
                textAlignment: .right,
                textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
        layout?
            .setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(
                textAlignment: .right,
                textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
        layout?
            .setMessageIncomingMessageTopLabelAlignment(LabelAlignment(
                textAlignment: .left,
                textInsets: UIEdgeInsets(top: 0, left: 18, bottom: Constants.outgoingAvatarOverlap, right: 0)))
        layout?.setMessageIncomingAvatarSize(CGSize(width: 30, height: 30))
        layout?
            .setMessageIncomingMessagePadding(UIEdgeInsets(
                top: -Constants.outgoingAvatarOverlap,
                left: -18,
                bottom: Constants.outgoingAvatarOverlap,
                right: 18))
        
        layout?.setMessageIncomingAccessoryViewSize(CGSize(width: 30, height: 30))
        layout?.setMessageIncomingAccessoryViewPadding(HorizontalEdgeInsets(left: 8, right: 0))
        layout?.setMessageIncomingAccessoryViewPosition(.messageBottom)
        layout?.setMessageOutgoingAccessoryViewSize(CGSize(width: 30, height: 30))
        layout?.setMessageOutgoingAccessoryViewPadding(HorizontalEdgeInsets(left: 0, right: 8))
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
    
    private func addTapGesture(to view: UIView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTitleTap))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
    }
    
    private func isLastSectionVisible() -> Bool {
        guard !messages.isEmpty else { return false }
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    private func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section - 1].sender.senderId
    }
    
    private func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messages.count else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section + 1].sender.senderId
    }
    
    private func sendTextMessage(_ inputBar: InputBarAccessoryView, _ text: String) {
        let outgoingMessage = GroupOutgoingMessage(
            sender: curUser,
            messageId: UUID().uuidString,
            sentDate: Date(),
            kind: .text(text),
            replyTo: nil
        )
        print("Sending")
        
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
                    let textMessage = self.interactor.mapToTextMessage(data)
                    self.messages[index] = textMessage
                    self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                    print("Sent")
                case .failure(_):
                    print("Failed")
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
                self.messagesCollectionView.performBatchUpdates({
                    messagesCollectionView.reloadSections(IndexSet(integer: index))
                }, completion: nil)
                inputBar.inputTextView.text = ""
                
                interactor.editTextMessage(Int64(editingMessageID) ?? 0, text) { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        switch result {
                        case .success(let data):
                            let editedText = self.interactor.mapToEditedMessage(data)
                            if let index = self.messages.firstIndex(where: {$0.messageId == String(editedText.oldTextUpdateID)}) {
                                guard var message = self.messages[index] as? GroupTextMessage else { return }
                                message.isEdited = true
                                message.editedMessage = editedText.newText
                                message.text = editedText.newText
                                self.messages[index] = message
                                self.messagesCollectionView.reloadSections([index])
                            }
                            print("Edited")
                        case .failure(let failure):
                            print("Failed to edit")
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
            replyTo: repliedMessage
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
                    let textMessage = self.interactor.mapToTextMessage(data)
                    self.messages[index] = textMessage
                    self.messagesCollectionView.reloadSections(IndexSet(integer: index))
                    print("Sent")
                case .failure(_):
                    print("Failed")
                }
                self.repliedMessage = nil
                self.replyPreviewView = nil
            }
        }
    }
    
    private func replyToMessage(_ messageIndexPath: IndexPath) {
        let message = messages[messageIndexPath.section]
        showReplyPreview(for: message)
    }
    
    private func editMessage(_ messageIndexPath: IndexPath) {
        let message = messages[messageIndexPath.section]
        if let message = message as? GroupTextMessage {
            messageInputBar.inputTextView.text = message.text
            messageInputBar.inputTextView.becomeFirstResponder()
            editingMessageID = message.messageId
            editingMessage = message.text
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
                      let index = self.messages.firstIndex(where: { $0.messageId == deletedMessage.messageId }) else { return }
                switch result {
                case .success(let data):
                    print("Deleted")
                case .failure(_):
                    self.messagesCollectionView.insertSections([self.messages.count - 1])
                    self.messagesCollectionView.reloadData()
                }
            }
        }
    }
    
    private func showReplyPreview(for message: MessageType) {
        replyPreviewView?.removeFromSuperview()
        
        let preview = ReplyPreviewView(message: message)
        preview.onClose = { [weak self] in
            self?.removeReplyPreview()
        }
        
        messageInputBar.topStackView.addArrangedSubview(preview)
        messageInputBar.topStackView.layoutIfNeeded()
        
        messageInputBar.topStackView.becomeFirstResponder()
        
        replyPreviewView = preview
        repliedMessage = message
    }
    
    private func removeReplyPreview() {
        replyPreviewView?.removeFromSuperview()
        messageInputBar.topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        messageInputBar.setNeedsLayout()
        replyPreviewView = nil
    }
    
    @objc private func handleTitleTap() {
        interactor.routeToChatProfile()
    }
    
    // MARK: - Actions
    @objc private func backButtonPressed() {
        interactor.routeBack()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension GroupChatViewController: MessagesDataSource {
    
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
        let message = messages[indexPath.section]
        
        if case .text = message.kind {
            let cell = messagesCollectionView.dequeueReusableCell(ReactionTextMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            cell.cellDelegate = self
            return cell
        }
        return UICollectionViewCell()
    }
}

extension GroupChatViewController: MessagesLayoutDelegate, MessagesDisplayDelegate {
    func textColor(for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> UIColor {
        isFromCurrentSender(message: message) ? .white : .darkText
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
        0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in _: MessagesCollectionView) -> CGFloat {
        (!isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message)) ? 16 : 10
        
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isPreviousMessageSameSender(at: indexPath) {
            let name = message.sender.displayName
            return NSAttributedString(
                string: name,
                attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
        return nil
    }
    
    func messageBottomLabelAttributedText(for message: any MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isNextMessageSameSender(at: indexPath), isFromCurrentSender(message: message) {
            return NSAttributedString(
                string: "Delivered",
                attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
        return nil
    }
    
    func messageBottomLabelAlignment(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment? {
        if isFromCurrentSender(message: message) {
            return LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16))
        } else {
            return LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0))
        }
    }
    
    func textCellSizeCalculator(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator? {
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            return ReactionMessageSizeCalculator(layout: layout)
        }
        return nil
    }
}

extension GroupChatViewController: MessageCellDelegate {
}

extension GroupChatViewController: MessageEditMenuDelegate {
    func didTapCopy(for message: IndexPath) {
        let message = messages[message.section]
        if let message = message as? GroupTextMessage {
            UIPasteboard.general.string = message.text
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
}

extension GroupChatViewController: CameraInputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        if editingMessageID != nil {
            sendEditRequest(inputBar, text)
        } else if repliedMessage != nil {
            
        } else {
            sendTextMessage(inputBar, text)
        }
    }
}

class ReactionTextMessageCell: TextMessageCell {
    
    weak var cellDelegate: MessageEditMenuDelegate?
        
    override func setupSubviews() {
        super.setupSubviews()
    }
    
    private func addLongPressMenu() {
        let interaction = UIContextMenuInteraction(delegate: self)
        messageContainerView.addInteraction(interaction)
        messageContainerView.isUserInteractionEnabled = true
    }
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        addLongPressMenu()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}

class ReactionMessageSizeCalculator: TextMessageSizeCalculator {
    
    open override func messageContainerSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        var size = super.messageContainerSize(for: message, at: indexPath)
        if let message = message as? GroupTextMessage {
            if message.reactions != nil {
                size.height += 20
            }
        }
        return size
    }
}

extension ReactionTextMessageCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let collectionView = self.superview as? UICollectionView,
              let indexPath = collectionView.indexPath(for: self) else {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
                self.cellDelegate?.didTapCopy(for: indexPath)
            }
            
            let reply = UIAction(title: "Reply to", image: UIImage(systemName: "pencil.and.scribble")) { _ in
                self.cellDelegate?.didTapReply(for: indexPath)
            }
            
            let edit = UIAction(title: "Edit", image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis")) { _ in
                self.cellDelegate?.didTapEdit(for: indexPath)
            }
            
            let deleteForMe = UIAction(title: "Удалить для меня", image: UIImage(systemName: "person")) { _ in
                self.cellDelegate?.didTapDelete(for: indexPath, mode: .DeleteModeForSender)
            }

            let deleteForEveryone = UIAction(title: "Удалить для всех", image: UIImage(systemName: "person.3.fill")) { _ in
                self.cellDelegate?.didTapDelete(for: indexPath, mode: .DeleteModeForAll)
            }

            let deleteMenu = UIMenu(title: "Удалить", image: UIImage(systemName: "trash"), options: .destructive, children: [deleteForMe, deleteForEveryone])
            
            return UIMenu(title: "", children: [copy, reply, edit, deleteMenu])
        }
    }
}
