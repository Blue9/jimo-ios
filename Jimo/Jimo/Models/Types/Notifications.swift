//
//  Notifications.swift
//  Jimo
//
//  Created by Jeff Rohlman on 3/2/21.
//

import Foundation

enum ItemType: String, Codable {
    case follow
    case like
    case comment
    case save
    case unknown
}

extension ItemType {
    public init(from decoder: Decoder) throws {
        self = try ItemType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

struct NotificationItem: Identifiable, Codable, Hashable {
    var id: String {
        itemId
    }
    var type: ItemType
    var createdAt: Date
    var user: PublicUser
    var itemId: String
    var post: Post?
    var comment: Comment?
}

struct NotificationFeedResponse: Codable {
    var notifications: [NotificationItem]
    var cursor: String?
}
