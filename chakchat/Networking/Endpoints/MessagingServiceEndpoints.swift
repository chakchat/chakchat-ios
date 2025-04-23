//
//  MessaginServiceEndpoints.swift
//  chakchat
//
//  Created by Кирилл Исаев on 26.02.2025.
//

import Foundation
/// если после последнего слова в ручке стоит слеш, значит в дальнейшем
/// нужно будет дописывать туда какую-то информацию.
/// Например в ручке "concreteChat" нужно потом в конце дописать {chatID}

enum MessagingServiceEndpoints {
    
    enum ChatsEndpoints: String {
        case getAllChats = "/api/messaging/v1.0/chat/all"
        case getConcreteChat = "/api/messaging/v1.0/chat/"
    }
    /// personalChat по итогу превращается в block, unblock, delete
    /// ручка blockChat должна иметь вид: "/api/messaging/v1.0/chat/personal/{chatID}/block"
    /// ручка unblockChat аналогично, но в конце /unblock
    /// ручка deleteChat аналогично, но в конце /delete/{deleteMode}
    enum PersonalChatEndpoints: String {
        case personalChat = "/api/messaging/v1.0/chat/personal"
    }
    /// ручка для установки времени автоудаления сообщений:
    /// "/api/messaging/v1.0/chat/personal/secret/{chatID}/expiration
    /// ручка для удаления:
    /// "/api/messaging/v1.0/chat/personal/secret/{chatID}/delete/{deleteMode}
    enum SecretPersonalChatEndpoints: String {
        case secretPersonalChat = "/api/messaging/v1.0/chat/personal/secret"
    }
    /// для изменения названия группы и удаления ручка:
    /// "/api/messaging/v1.0/chat/group/{chatID}"
    /// для добавленяи нового участника и удаления:
    /// "/api/messaging/v1.0/chat/group/{chatID}/member/{memberID}"
    /// для обновления и удаления фотки группового чата:
    /// "/api/messaging/v1.0/chat/group/{chatID}/photo"
    enum GroupChatEndpoints: String {
        case groupChat = "/api/messaging/v1.0/chat/group"
    }
    /// все аналогично ручкам для обычного группового чата
    enum SecretGroupChatEndpoints: String {
        case secretGroupChat = "/api/messaging/v1.0/chat/group/secret"
    }

    enum PersonalUpdateEndpoints: String {
        case searchMessages = "/update/message/search"
        case sendTextMessage = "/update/message/text"
        case updateMessage = "/update/message"
        case sendFile = "/update/message/file"
        case sendReaction = "/update/reaction"
        case forwardMessage = "/update/text-message/forward"
        case forwardFile = "/update/file-message/forward"
    }
    
    enum GroupUpdateEndpoint: String {
        case searchMessages = "/update/message/search"
        case sendTextMessage = "/update/message/text"
        case updateMessage = "/update/message"
        case sendFile = "/update/message/file"
        case sendReaction = "/update/reaction"
        case forwardMessage = "/update/text-message/forward"
        case forwardFile = "/update/file-message/forward"
    }
    
    enum SecretUpdateEndpoints: String {
        case update = "/update/secret"
    }
}
