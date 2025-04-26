//
//  UpdatedGroupPhotoEvent.swift
//  chakchat
//
//  Created by Кирилл Исаев on 12.03.2025.
//

import UIKit

final class UpdatedGroupPhotoEvent: Event {
    let photo: UIImage?
    let photoURL: URL?
    let chatID: UUID
    
    init(photo: UIImage?, photoURL: URL?, chatID: UUID) {
        self.photo = photo
        self.photoURL = photoURL
        self.chatID = chatID
    }
}
