//
//  ProfileViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/14/20.
//

import Foundation


class ProfileVM: ObservableObject {
    @Published var user: User? = nil
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
        self.model.getUser(username: username, onComplete: { user in
            DispatchQueue.main.async {
                self.failedToLoad = user == nil
                self.refreshing = false
                self.user = user
            }
        })
    }
    
    init(model: AppModel, username: String) {
        self.model = model
        self.username = username
        refresh()
    }
    
    func getName(user: User) -> String {
        return user.firstName + " " + user.lastName
    }
}
