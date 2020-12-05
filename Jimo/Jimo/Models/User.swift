//
//  User.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import Foundation

typealias uid = String

struct User {
    var id: uid = "uid"
    var username: String
    var firstName: String
    var lastName: String
    var profilePicture: String?
    var postCount: Int
    var followerCount: Int
    var followingCount: Int
}

extension User {
    init?(json: [String: Any]) {
        guard let username = json["username"] as? String,
            let firstName = json["firstName"] as? String,
            let lastName = json["lastName"] as? String,
            let postCount = json["postCount"] as? Int,
            let followerCount = json["followerCount"] as? Int,
            let followingCount = json["followingCount"] as? Int
        else {
            return nil
        }

        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.profilePicture = json["profilePicture"] as? String
        self.postCount = postCount
        self.followerCount = followerCount
        self.followingCount = followingCount
    }
}
