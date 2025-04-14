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
    
    // MARK: - Initialization
    init(interactor: GroupChatBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            if let update = update as? GroupFileMessage {
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
    
    func customCell(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        if case .custom(let custom) = message.kind {
            if custom is DeleteKind {
                return messagesCollectionView.dequeueReusableCell(withReuseIdentifier: "CustomTextCell", for: indexPath)
            }
        }
        return UICollectionViewCell()
    }
}

extension GroupChatViewController: MessagesLayoutDelegate, MessagesDisplayDelegate {
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
        if let message = message as? ReplyMessage {
            return NSAttributedString(
                string: "You replied",
                attributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                    NSAttributedString.Key.foregroundColor: UIColor.darkGray,
                ]
            )
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
        if let message = message as? ReplyMessage {
            return 40
        } else if let message = message as? MessageForKit {
            if case .text(let textContent) = message.content {
                if textContent.replyTo != nil {
                    return 40
                } else {
                    if isFromCurrentSender(message: message) {
                        return !isPreviousMessageSameSender(at: indexPath) ? 20 : 0
                    } else {
                        return !isPreviousMessageSameSender(at: indexPath) ? (20) : 0
                    }
                }
            }
        }
        return 0
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in _: MessagesCollectionView) -> CGFloat {
        (!isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message)) ? 16 : 10
        
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at _: IndexPath) -> NSAttributedString? {
        nil
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
    
    func messageBottomLabelAlignment(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment? {
        if isFromCurrentSender(message: message) {
            return LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16))
        } else {
            return LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0))
        }
    }
}

extension GroupChatViewController: MessageCellDelegate {
    
}

extension GroupChatViewController: CameraInputBarAccessoryViewDelegate {
   
}

