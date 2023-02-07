//
//  ModelProvider.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/6/23.
//

import Foundation

class ModelProvider {
    static private(set) var postModels: [PostId: PostVM] = [:]

    // TODO: Update AppState to set the view models
    /**
     Only AppState should set shouldUpdate to true. Otherwise when SwiftUI rebuilds views they might call this function and
     update the post view model with outdated data. This isn't a problem for AppState because it will only update right after
     receiving data from the API, aka it will be up-to-date data.
     */
    static func getPostModel(for post: Post, _ shouldUpdate: Bool = false) -> PostVM {
        if let vm = postModels[post.id] {
            if vm.post != post && shouldUpdate {
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
