//
//  ModelProvider.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/6/23.
//

import Foundation

class ModelProvider {
    static private(set) var postModels: [PostId: PostVM] = [:]

    static func getPostModel(for post: Post, shouldWrite: Bool = true) -> PostVM {
        if let vm = postModels[post.id] {
            if vm.post != post && shouldWrite {
                DispatchQueue.main.async {
                    print("Updating postVM value")
                    vm.post = post
                }
            }
            return vm
        } else {
            let vm = PostVM(post: post)
            postModels[post.id] = vm
            return vm
        }
    }
}
