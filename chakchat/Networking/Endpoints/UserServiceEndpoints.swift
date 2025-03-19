//
//  UserServiceEndpoints.swift
//  chakchat
//
//  Created by Кирилл Исаев on 12.02.2025.
//

import Foundation
/// если на конце ручки стоит / => нужно будет дописывать
/// {parameter} после этого слеша
enum UserServiceEndpoints: String {
    case user = "/api/user/v1.0/user/"
    case username = "/api/user/v1.0/user/username/"
    case usernameAvailability = "/api/user/v1.0/username/"
    case users = "/api/user/v1.0/users"
    
    case me = "/api/user/v1.0/me"
    case photo = "/api/user/v1.0/me/profile-photo"
    case meRestrictions = "/api/user/v1.0/me/restrictions"

    case teapot = "api/user/v1.0/are-you-a-real-teapot"
}
