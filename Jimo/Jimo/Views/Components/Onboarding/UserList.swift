//
//  UserList.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/14/21.
//

import SwiftUI

struct UserList<T: SuggestedUserStore>: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var userStore: T
    
    var users: [PublicUser] {
        userStore.allUsers
    }
    
    private let columns: [GridItem] = [
        GridItem(.flexible(minimum: 50), spacing: 10),
        GridItem(.flexible(minimum: 50), spacing: 10),
        GridItem(.flexible(minimum: 50), spacing: 10)
    ]
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(users) { (user: PublicUser) in
                        SuggestedUserView(userStore: userStore, user: user)
                    }
                }
                .padding(.bottom, 50)
            }
            
            VStack {
                Button(action: {
                    userStore.follow(appState: appState)
                }) {
                    if userStore.followingLoading {
                        LargeButton {
                            ProgressView()
                        }
                    } else {
                        LargeButton("Follow")
                    }
                }
                .disabled(userStore.followingLoading)
                .padding(.horizontal, 40)
                .padding(.bottom, 5)
                
                Text("Clear selection")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .onTapGesture {
                        userStore.clearAll()
                    }
                
                Text("Select all")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.top, 2)
                    .onTapGesture {
                        userStore.selectAll()
                    }
            }
            .padding(.top, 30)
        }
    }
}
