//
//  User.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import Foundation

typealias username = String

protocol User {
    var username: username { get set }
    var firstName: String { get set }
    var lastName: String { get set }
    var profilePictureUrl: String? { get set }
    var postCount: Int { get set }
    var followerCount: Int { get set }
    var followingCount: Int { get set }
}

struct PublicUser: User, Codable, Equatable {
    var username: username
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
    var created: PublicUser?
    var error: UserFieldError?
}
