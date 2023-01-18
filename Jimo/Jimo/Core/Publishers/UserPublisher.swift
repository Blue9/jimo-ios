//
//  UserPublisher.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/27/21.
//

import Foundation

struct UserRelationPayload {
    var username: String
    var relation: UserRelation?
}

class UserPublisher {
    let notificationCenter = NotificationCenter.default

    static let userRelationChanged = Notification.Name("user:relation")

    func userRelationChanged(username: String, relation: UserRelation?) {
        notificationCenter.post(name: UserPublisher.userRelationChanged, object: UserRelationPayload(username: username, relation: relation))
    }
}
