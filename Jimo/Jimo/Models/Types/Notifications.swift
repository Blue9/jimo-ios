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
    case unknown
}

extension ItemType {
    public init(from decoder: Decoder) throws {
        self = try ItemType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

struct NotificationItem: Codable, Hashable {
    var type: ItemType
    var createdAt: Date
    var user: PublicUser
    var itemId: String
    var post: Post?
}

struct NotificationFeedResponse: Codable {
    var notifications: [NotificationItem]
    var cursor: String?
}
