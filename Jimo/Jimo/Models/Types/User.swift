//
//  User.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import Foundation

typealias username = String
typealias UserId = String

protocol User {
    var username: username { get set }
    var firstName: String { get set }
    var lastName: String { get set }
    var profilePictureUrl: String? { get set }
    var postCount: Int { get set }
    var followerCount: Int { get set }
    var followingCount: Int { get set }
}

struct PublicUser: User, Codable, Identifiable, Equatable {
    var id: UserId {
        username
    }
    var username: username
    var firstName: String
    var lastName: String
    var profilePictureUrl: String?
    var postCount: Int
    var followerCount: Int
    var followingCount: Int
}


struct UserPreferences: Codable {
    var followNotifications: Bool
    var postLikedNotifications: Bool
    var postNotifications: Bool
}


struct CreateUserRequest: Codable {
    var username: String
    var firstName: String
    var lastName: String
}


struct CreateUserResponse: Codable {
    var created: PublicUser?
    var error: UserFieldError?
}


struct UpdateProfileRequest: Codable {
    var profilePictureUrl: String?
    var username: String
    var firstName: String
    var lastName: String
}


struct UpdateProfileResponse: Codable {
    var user: PublicUser?
    var error: UserFieldError?
}


struct UserFieldError: Codable {
    var uid: String?
    var username: String?
    var firstName: String?
    var lastName: String?
    var other: String?
}


struct FollowUserResponse: Codable {
    var followed: Bool
    var followers: Int?
}


struct InviteUserRequest: Codable {
    var phoneNumber: String
}


struct UserInviteStatus: Codable {
    var invited: Bool
}


struct UserWaitlistStatus: Codable {
    var invited: Bool
    var waitlisted: Bool
}


struct PhoneNumbersRequest: Codable {
    var phoneNumbers: [String]
}
