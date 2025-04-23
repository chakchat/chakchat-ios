//
//  GroupChatProfileProtocols.swift
//  chakchat
//
//  Created by Кирилл Исаев on 09.03.2025.
//

import UIKit

protocol GroupChatProfileBusinessLogic: SearchInteractor {
    func passChatData()
    
    func createSecretGroup()
    
    func deleteGroup()
    func addMember(_ memberID: UUID)
    func deleteMember(_ memberID: UUID)
    
    func updateGroupInfo(_ name: String, _ description: String?)
    func updateGroupPhoto(_ image: UIImage?)
    
    func handleUpdatedGroupInfoEvent(_ event: UpdatedGroupInfoEvent)
    func handleUpdatedGroupPhotoEvent(_ event: UpdatedGroupPhotoEvent)
    
    func getUserDataByID(_ users: [UUID], completion: @escaping ([ProfileSettingsModels.ProfileUserData]?) -> Void)
    
    func routeToChatMenu()
    func routeToEdit()
    func routeToProfile(_ user: ProfileSettingsModels.ProfileUserData)
    func routeBack()
}

protocol GroupChatProfilePresentationLogic {
    func passChatData(_ chatData: ChatsModels.GeneralChatModel.ChatData, _ isAdmin: Bool)
    func updateGroupInfo(_ name: String, _ description: String?)
    func updateGroupPhoto(_ image: UIImage?)
}

protocol GroupChatProfileWorkerLogic {
    func createSecretGroup(_ name: String, _ description: String?, _ members: [UUID], completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void)
    
    func deleteGroup(
        _ chatID: UUID,
        completion: @escaping (Result<EmptyResponse, Error>) -> Void
    )
    func addMember(
        _ chatID: UUID,
        _ memberID: UUID,
        completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void
    )
    func deleteMember(
        _ chatID: UUID,
        _ memberID: UUID,
        completion: @escaping (Result<ChatsModels.GeneralChatModel.ChatData, Error>) -> Void
    )
    func fetchUsers(
        _ name: String?,
        _ username: String?,
        _ page: Int,
        _ limit: Int,
        completion: @escaping (Result<ProfileSettingsModels.Users, Error>) -> Void
    )
    
    func getUserDataByID(_ users: [UUID], completion: @escaping ([ProfileSettingsModels.ProfileUserData]?) -> Void)
    
    func getMyID() -> UUID
}
