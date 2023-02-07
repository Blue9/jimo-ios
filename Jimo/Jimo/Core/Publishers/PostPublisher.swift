//
//  PostPublisher.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/19/21.
//

import Foundation

class PostPublisher {
    let notificationCenter = NotificationCenter.default

    static let postCreated = Notification.Name("post:created")
    static let postDeleted = Notification.Name("post:deleted")

    func postCreated(post: Post) {
        notificationCenter.post(name: PostPublisher.postCreated, object: post)
    }

    func postDeleted(postId: PostId) {
        notificationCenter.post(name: PostPublisher.postDeleted, object: postId)
    }
}
