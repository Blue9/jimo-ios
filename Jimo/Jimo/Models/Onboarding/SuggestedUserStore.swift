//
//  SuggestedUserStore.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/14/21.
//

import Foundation

protocol SuggestedUserStore: ObservableObject {
    var allUsers: [PublicUser] { get }
    var selected: [PublicUser] { get }
    var followingLoading: Bool { get }
    
    func follow(appState: AppState)
    func toggleSelected(for contact: PublicUser)
    func clearAll()
    func selectAll()
}
