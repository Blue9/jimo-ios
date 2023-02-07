//
//  ModelProvider.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/6/23.
//

import Foundation

class ModelProvider {
    static private(set) var postModels: [PostId: PostVM] = [:]

    static func upsertPostModel(_ post: Post) {
        let model = getPostModel(for: post)
        model.post = post
    }

    static func deletePostModel(_ post: Post) {
        postModels.removeValue(forKey: post.id)
    }

    static func getPostModel(for post: Post) -> PostVM {
        if let model = postModels[post.id] {
            return model
        } else {
            let model = PostVM(post: post)
            postModels[post.id] = model
            return model
        }
    }
}
