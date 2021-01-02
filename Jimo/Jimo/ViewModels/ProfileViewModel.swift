//
//  ProfileViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/14/20.
//

import Foundation


class ProfileVM: ObservableObject {
    @Published var user: User? = nil
    @Published var posts: [Post]? = nil
    @Published var refreshing = false {
        didSet {
            if oldValue == false && refreshing == true {
                self.refresh()
            }
        }
    }
    @Published var failedToLoad = false
    
    let username: String
    let model: AppModel
    
    func refresh() {
        model.getUser(username: username, onComplete: { user, error in
            DispatchQueue.main.async {
                self.failedToLoad = user == nil
                self.refreshing = false
                if user != nil {
                    self.user = user
                }
            }
        })
        // TODO fix the logic here, should handle both at once
        model.getPosts(username: username, onComplete: { posts, error in
            DispatchQueue.main.async {
                print("Loaded posts")
                self.posts = posts
                // TODO handle error
            }
        })
    }
    
    init(model: AppModel, username: String, user: User? = nil) {
        self.model = model
        self.username = username
        self.user = user
        if user == nil {
            refresh()
        }
    }
    
    func getName(user: User) -> String {
        return user.firstName + " " + user.lastName
    }
}
