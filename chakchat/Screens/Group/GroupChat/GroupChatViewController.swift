//
//  GroupChatViewController.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import PhotosUI
import AVKit
import UniformTypeIdentifiers

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
    
    private var usersInfo: [ProfileSettingsModels.ProfileUserData] = []
    private let color = UIColor.random()
    
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
        loadUsers()
        loadFirstMessages()
        configureUI()
        interactor.passChatData()
    }
    
    private func loadUsers() {
        interactor.loadUsers() { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let users):
                    self.usersInfo = users
                case .failure(let failure):
                    print(failure)
                }
            }
        }
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
    
    func configureWithData(_ chatData: ChatsModels.GeneralChatModel.ChatData, _ myID: UUID) {
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
            
            curUser = GroupSender(senderId: myID.uuidString, displayName: "", avatar: nil)
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
        layout?.textMessageSizeCalculator.outgoingAvatarSize = .zero
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
        if type == .edit {
            messageInputBar.inputTextView.text = ""
        }
    }
    
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
    //MARK: - File sendings
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
        
        if case .text = message.kind {
            let cell = messagesCollectionView.dequeueReusableCell(ReactionTextMessageCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            cell.cellDelegate = self
            return cell
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
    
    func configureAvatarView(_ avatarView: AvatarView, for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let sender = message.sender as? GroupSender else { return }
        guard let userID = usersInfo.firstIndex(where: { $0.id == UUID(uuidString: sender.senderId)}) else { return }
        let user = usersInfo[userID]
        if let url = user.photo {
            if let cachedImage = ImageCacheManager.shared.getImage(for: url as NSURL) {
                avatarView.set(avatar: Avatar(image: cachedImage))
            }
            DispatchQueue.global(qos: .userInteractive).async {
                URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data, error == nil, let image = UIImage(data: data) else {
                        return
                    }
                    ImageCacheManager.shared.saveImage(image, for: url as NSURL)
                    DispatchQueue.main.async {
                        avatarView.set(avatar: Avatar(image: image))
                    }
                }.resume()
            }
        } else {
            let image = UIImage.imageWithText(
                text: user.name,
                size: CGSize(width: avatarView.frame.width, height: avatarView.frame.height),
                color: color,
                borderWidth: Constants.borderWidth
            )
            avatarView.set(avatar: Avatar(image: image))
        }
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
            return LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0))
        }
    }
    //MARK: - Size calculators
    func textCellSizeCalculator(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator? {
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            if case .text = message.kind {
                if message is GroupOutgoingMessage || message is GroupTextMessage {
                    return ReactionMessageSizeCalculator(layout: layout)
                }
                if message is OutgoingFileMessage || message is GroupFileMessage {
                    return FileMessageCellSizeCalculator(layout: layout)
                }
            }
        }
        return nil
    }
    
    func photoCellSizeCalculator(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator? {
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            if case .photo = message.kind {
                return PhotoMessageCellSizeCalculator(layout: layout)
            }
        }
        return nil
    }
}

extension GroupChatViewController: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
            return
        }
        if let userID = UUID(uuidString: message.sender.senderId) {
            interactor.routeToUserProfile(userID)
        }
    }
    
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
//MARK: EditMenuDelegate
extension GroupChatViewController: TextMessageEditMenuDelegate, FileMessageEditMenuDelegate {
    
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
    
    func didSelectReaction(_ emojiID: Int64, _ emoji: String, _ picked: Bool, for indexPath: IndexPath) {
        if picked {
            // добавляем
        } else {
            // убираем
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
        print("Load file")
    }
}
// MARK: - InputBar delegate
extension GroupChatViewController: CameraInputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        if editingMessageID != nil {
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
                if let mimeType = mimeTypeForURL(url) {
                    if !mimeType.contains("video") {
                        sendFile(url, mimeTypeForURL(url))
                    } else {
                        sendVideo(url)
                    }
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

//MARK: CustomTextMessageCell
class ReactionTextMessageCell: TextMessageCell {
    
    weak var cellDelegate: TextMessageEditMenuDelegate?
    var indexPath: IndexPath?

    private var messageStatus: UILabel = UILabel()
    private var replyView: UIView = UIView()
    private var replyMessage: UILabel = UILabel()
    private var reactionsView: UIView = UIView()
    private var reactionsStack: UIStackView = UIStackView()
    
    private var pickedReaction: String? // реакция которую мог поставить пользователь на сообщение

    private var messageTopConstraint: NSLayoutConstraint?
    private var messageBottomConstraint: NSLayoutConstraint?

    override func setupSubviews() {
        super.setupSubviews()
        configureCell()
    }
    
    private func configureCell() {
        configureMessageStatus()
        configureReplyView()
        configureReplyMessage()
        configureReactionsView()
        setupConstraints()
    }

    private func configureMessageStatus() {
        messageStatus.translatesAutoresizingMaskIntoConstraints = false
        messageContainerView.addSubview(messageStatus)
        messageStatus.font = UIFont.systemFont(ofSize: 10)
        messageStatus.textColor = .white
    }

    private func configureReplyView() {
        replyView.translatesAutoresizingMaskIntoConstraints = false
        replyView.backgroundColor = .lightGray
        replyView.layer.cornerRadius = 10
        replyView.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapReplyView))
        replyView.addGestureRecognizer(tap)
        replyView.isUserInteractionEnabled = true
        messageContainerView.addSubview(replyView)
    }

    private func configureReplyMessage() {
        replyMessage.translatesAutoresizingMaskIntoConstraints = false
        replyMessage.numberOfLines = 1
        replyMessage.textColor = .white
        replyMessage.font = UIFont.systemFont(ofSize: 10)
        replyMessage.textAlignment = .left
        replyMessage.lineBreakMode = .byTruncatingTail
        replyView.addSubview(replyMessage)
    }
    
    private func configureReactionsView() {
        reactionsView.translatesAutoresizingMaskIntoConstraints = false
        messageContainerView.addSubview(reactionsView)
        
        reactionsStack.axis = .horizontal
        reactionsStack.distribution = .fill
        reactionsStack.alignment = .center
        reactionsStack.spacing = 8
        reactionsStack.translatesAutoresizingMaskIntoConstraints = false
        reactionsView.addSubview(reactionsStack)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            messageStatus.widthAnchor.constraint(equalToConstant: 10),
            messageStatus.heightAnchor.constraint(equalToConstant: 10),
            messageStatus.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -5),
            messageStatus.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -1)
        ])

        NSLayoutConstraint.activate([
            replyView.topAnchor.constraint(equalTo: messageContainerView.topAnchor, constant: 4),
            replyView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: 16),
            replyView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -16),
            replyView.heightAnchor.constraint(equalToConstant: 40)
        ])

        NSLayoutConstraint.activate([
            replyMessage.centerYAnchor.constraint(equalTo: replyView.centerYAnchor),
            replyMessage.leadingAnchor.constraint(equalTo: replyView.leadingAnchor, constant: 3),
            replyMessage.widthAnchor.constraint(equalToConstant: 280)
        ])
        
        NSLayoutConstraint.activate([
            reactionsView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            reactionsView.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -4),
            reactionsView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: 8),
            reactionsView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -8),
            reactionsView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            reactionsStack.topAnchor.constraint(equalTo: reactionsView.topAnchor, constant: 4),
            reactionsStack.bottomAnchor.constraint(equalTo: reactionsView.bottomAnchor, constant: -4),
            reactionsStack.leadingAnchor.constraint(equalTo: reactionsView.leadingAnchor, constant: 8),
        ])

        // Message Label constraints
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageTopConstraint = messageLabel.topAnchor.constraint(equalTo: messageContainerView.topAnchor)
        messageBottomConstraint = messageLabel.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor)
        
        NSLayoutConstraint.activate([
            messageTopConstraint!,
            messageBottomConstraint!,
            messageLabel.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        replyView.isHidden = true
        replyMessage.text = nil
        reactionsView.isHidden = true
        messageStatus.layer.removeAllAnimations()
        messageTopConstraint?.constant = 0
        messageBottomConstraint?.constant = 0
    }

    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        addLongPressMenu()
        
        reactionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        self.indexPath = indexPath

        if let message = message as? GroupMessageStatusProtocol {
            messageStatus.text = message.status.rawValue
            if message.status == .sending {
                startSendingAnimation(in: self)
            } else {
                if message.status == .read {
                    messageStatus.textColor = .chakChat
                } else if message.status == .error {
                    messageStatus.text = MessageStatus.error.rawValue
                }
                messageStatus.layer.removeAllAnimations()
            }
        }

        replyView.isHidden = true
        replyMessage.text = nil
        messageTopConstraint?.isActive = false
        messageTopConstraint = messageLabel.topAnchor.constraint(equalTo: messageContainerView.topAnchor)
        
        reactionsView.isHidden = true
        messageBottomConstraint?.isActive = false
        messageBottomConstraint = messageLabel.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor)
        
        messageTopConstraint?.isActive = true
        messageBottomConstraint?.isActive = true

        if let message = message as? GroupTextMessage {
            if let replyTo = message.replyTo {
                replyView.isHidden = false
                replyMessage.text = replyTo

                messageTopConstraint?.isActive = false
                messageTopConstraint = messageLabel.topAnchor.constraint(equalTo: replyView.bottomAnchor, constant: 5)
                messageTopConstraint?.isActive = true
            }
            if let pickedReaction = message.curUserPickedReaction {
                self.pickedReaction = pickedReaction
            }
            if let reactions = message.reactions {
                reactionsView.isHidden = false

                messageBottomConstraint?.isActive = false
                messageBottomConstraint = messageLabel.bottomAnchor.constraint(equalTo: reactionsView.topAnchor, constant: 0)
                messageBottomConstraint?.isActive = true
                
                let reactionCount = reactions.reduce(into: [String: Int]()) { result, reaction in
                    result[reaction.value, default: 0] += 1
                }
                
                for (reaction, count) in reactionCount {
                    let isPicked = reaction == pickedReaction
                    
                    let keys = reactions
                        .filter { $0.value == reaction }
                        .map {$0.key }
                    let sortedKeys = keys.sorted()
                    
                    let reactionView = ReactionView(reaction: getEmoji(reaction) ?? "bzZZ", reactions: sortedKeys, count: count, isPicked: isPicked)
                    
                    reactionView.onReactionChanged = { [weak self] reaction, emojiString, picked in
                        self?.cellDelegate?.didSelectReaction(reaction, emojiString, picked, for: indexPath)
                    }
                    
                    reactionView.onRemove = { [weak self, weak reactionView] in
                        guard let reactionView = reactionView else { return }
                        self?.reactionsStack.removeArrangedSubview(reactionView)
                        reactionView.removeFromSuperview()
                    }
                    reactionsStack.addArrangedSubview(reactionView)
                }
            }
        }
    }

    private func addLongPressMenu() {
        let interaction = UIContextMenuInteraction(delegate: self)
        messageContainerView.addInteraction(interaction)
        messageContainerView.isUserInteractionEnabled = true
    }
    
    private func getEmoji(_ emoji: String) -> String? {
        switch emoji {
        case "heart": return "❤️"
        case "like": return "👍"
        case "thunder": return "⚡️"
        case "cry": return "😭"
        case "dislike": return "👎"
        case "bzZZ": return "🐝"
        default: return nil
        }
    }
    
    private func startSendingAnimation(in cell: ReactionTextMessageCell) {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = .infinity
        cell.messageStatus.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    @objc private func didTapReplyView() {
        guard let indexPath = indexPath else { return }
        cellDelegate?.didTapReply(indexPath)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
}

class ReactionMessageSizeCalculator: TextMessageSizeCalculator {
    
    private let emojiWidth = 40
    private let spacing = 8
    
    open override func messageContainerSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        var size = super.messageContainerSize(for: message, at: indexPath)
        let maxWidth = messageContainerMaxWidth(for: message, at: indexPath)
        if let message = message as? GroupTextMessage {
            if let replyTo = message.replyTo {
                size.height += 40
                let replyToSize = replyTo.width(withConstrainedHeight: 16, font: .systemFont(ofSize: 16))
                if replyToSize > size.width {
                    size.width = replyToSize > maxWidth ? maxWidth : replyToSize
                }
            }
            if let reactions = message.reactions {
                var set = Set<String>()
                reactions.forEach { reaction in
                    set.insert(reaction.value)
                }
                var reactionViewWidth = spacing * 2
                size.height += 50
                set.forEach { reaction in
                    reactionViewWidth += emojiWidth
                    reactionViewWidth += spacing
                }
                if size.width < CGFloat(reactionViewWidth) {
                    size.width = CGFloat(reactionViewWidth)
                }
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
            
            let reactions = UIAction(title: "Add Reaction", image: UIImage(systemName: "face.smiling")) { _ in
                   self.showReactionsMenu(for: indexPath)
            }
            
            let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { _ in
                self.cellDelegate?.didTapCopy(for: indexPath)
            }
            
            let reply = UIAction(title: "Reply to", image: UIImage(systemName: "pencil.and.scribble")) { _ in
                self.cellDelegate?.didTapReply(for: indexPath)
            }
            
            let edit = UIAction(title: "Edit", image: UIImage(systemName: "rectangle.and.pencil.and.ellipsis")) { _ in
                self.cellDelegate?.didTapEdit(for: indexPath)
            }
            
            let deleteForMe = UIAction(title: "Delete for me", image: UIImage(systemName: "person")) { _ in
                self.cellDelegate?.didTapDelete(for: indexPath, mode: .DeleteModeForSender)
            }

            let deleteForEveryone = UIAction(title: "Delete for all", image: UIImage(systemName: "person.3.fill")) { _ in
                self.cellDelegate?.didTapDelete(for: indexPath, mode: .DeleteModeForAll)
            }

            let deleteMenu = UIMenu(title: "Delete", image: UIImage(systemName: "trash"), options: .destructive, children: [deleteForMe, deleteForEveryone])
            
            return UIMenu(title: "", children: [copy, reactions, reply, edit, deleteMenu])
        }
    }
    
    private func showReactionsMenu(for indexPath: IndexPath) {
        let reactionsVC = ReactionsPreviewViewController()
        reactionsVC.preferredContentSize = CGSize(width: 280, height: 50)
        reactionsVC.modalPresentationStyle = .popover
        reactionsVC.reactionSelected = { [weak self] emoji in
            self?.cellDelegate?.didSelectReaction(2, "", true, for: indexPath) // всегда верно потому что через то меню мы можешь только поставить реакцию, но не удалить ее
        }
        if let popover = reactionsVC.popoverPresentationController {
            popover.sourceView = self
            popover.sourceRect = self.bounds
            popover.permittedArrowDirections = []
            popover.delegate = self
        }
        self.window?.rootViewController?.present(reactionsVC, animated: true)
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        params.shadowPath = UIBezierPath(rect: .zero)
        params.visiblePath = UIBezierPath(rect: self.messageContainerView.bounds)
        return UITargetedPreview(view: self.messageContainerView, parameters: params)
    }
}

class ReactionsPreviewViewController: UIViewController {
    private let emojis = ["❤️", "👍", "⚡️", "😭", "👎", "🐝"]
    private var stackView: UIStackView!
    var reactionSelected: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = .clear
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        view.addSubview(blurView)
        
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        blurView.contentView.addSubview(stackView)
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            blurView.widthAnchor.constraint(equalToConstant: 280),
            blurView.heightAnchor.constraint(equalToConstant: 50),
            blurView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            blurView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            stackView.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: blurView.centerYAnchor)
        ])
        
        // Add reaction buttons
        emojis.forEach { emoji in
            let button = UIButton(type: .system)
            button.setTitle(emoji, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 28)
            button.addTarget(self, action: #selector(reactionTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
    }
    
    @objc private func reactionTapped(_ sender: UIButton) {
        guard let emoji = sender.title(for: .normal) else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                sender.transform = .identity
            } completion: { _ in
                self.reactionSelected?(emoji)
                self.dismiss(animated: true)
            }
        }
    }
}

extension ReactionTextMessageCell: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
    
        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}

extension UIImage {
    func scaledToFit(maxSize: CGSize) -> UIImage {
        let aspectRatio = min(
            maxSize.width / size.width,
            maxSize.height / size.height
        )
        
        let newSize = CGSize(
            width: size.width * aspectRatio,
            height: size.height * aspectRatio
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
