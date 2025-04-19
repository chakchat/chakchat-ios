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
    
    init(photo: UIImage?, photoURL: URL? = nil) {
        self.photo = photo
        self.photoURL = photoURL
    }
}
