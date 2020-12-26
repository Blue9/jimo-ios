//
//  User.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import Foundation

typealias uid = String

struct User: Codable, Identifiable {
    let id: UUID = UUID() // ignore the warning
    var username: String
    var firstName: String
    var lastName: String
    var profilePictureUrl: String?
    var postCount: Int
    var followerCount: Int
    var followingCount: Int
}


struct CreateUserRequest: Codable {
    var username: String
    var firstName: String
    var lastName: String
}


struct UserFieldError: Codable {
    var username: String?
    var firstName: String?
    var lastName: String?
}


struct CreateUserResponse: Codable {
    var created: Bool
    var error: UserFieldError?
}
