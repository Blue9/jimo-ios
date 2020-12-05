//
//  AppViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/14/20.
//

import Foundation


protocol AppVM {
    func getUser(username: String, onComplete: @escaping (User?) -> Void)
    
    func getName(user: User) -> String
}


class LocalVM: AppVM {
    func getUser(username: String, onComplete: @escaping (User?) -> Void) {
        onComplete(User(
            id: "uid",
            username: "gautam",
            firstName: "Gautam",
            lastName: "Mekkat",
            profilePicture: nil,
            postCount: 150,
            followerCount: 800,
            followingCount: 800))
    }
    
    func getName(user: User) -> String {
        return user.firstName + " " + user.lastName
    }
}


class RemoteVM: AppVM {
    let model = AppModel()
    
    func getUser(username: String, onComplete: @escaping (User?) -> Void) {
        model.getUser(username: username, onComplete: onComplete)
    }
    
    func getName(user: User) -> String {
        return user.firstName + " " + user.lastName
    }
}
