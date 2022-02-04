//
//  UserFilter.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/7/22.
//

import SwiftUI

struct CircularCheckbox: View {
    var selected: Bool
    var userLoaded: Bool
    
    var imageName: String {
        if !userLoaded {
            return "arrow.down.circle"
        } else if selected {
            return "checkmark.circle.fill"
        } else {
            return "circle"
        }
    }
    
    var body: some View {
        Image(systemName: imageName)
            .font(.system(size: 30, weight: .light))
            .foregroundColor(.blue)
    }
}


struct SelectableUser: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    
    @ObservedObject var mapViewModel: MapViewModelV2
    var user: PublicUser
    @Binding var selectedUsers: Set<UserId>
    
    @State private var loadingPosts = false
    
    var selected: Bool {
        selectedUsers.contains(user.id)
    }
    
    var isCurrentUser: Bool {
        if case let .user(currentUser) = appState.currentUser {
            return currentUser.id == user.id
        }
        return false
    }
    
    var userLoaded: Bool {
        mapViewModel.allUsers.keys.contains(user.id)
    }
    
    var allPostsLoaded: Bool {
        mapViewModel.numLoadedPostsByUser[user.id] == user.postCount
    }
    
    @ViewBuilder var loadedPostsInfo: some View {
        VStack {
            Text("Loaded \(mapViewModel.numLoadedPostsByUser[user.id] ?? 0)/\(user.postCount) pins")
            if !allPostsLoaded {
                Button(action: {
                    self.loadingPosts = true
                    mapViewModel.loadMoreAndUpdateMap(
                        appState: appState,
                        globalViewState: viewState,
                        forUser: user, onComplete: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.loadingPosts = false
                            }
                        })
                }) {
                    Text("Load more")
                }
            }
        }
        .font(.caption)
    }
    
    @ViewBuilder var profilePicture: some View {
        ZStack {
            URLImage(
                url: user.profilePictureUrl,
                loading: Image(systemName: "person.crop.circle"),
                thumbnail: true
            )
                .foregroundColor(.gray)
                .frame(width: 40, height: 40)
                .cornerRadius(20)
        }
    }
    
    var body: some View {
        HStack {
            profilePicture

            if isCurrentUser {
                Text("Me")
                    .font(.system(size: 15))
                    .bold()
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            } else {
                VStack(alignment: .leading) {
                    Text(user.username.lowercased())
                        .font(.system(size: 15))
                        .bold()
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)

                    Text("\(user.firstName) \(user.lastName)")
                        .font(.system(size: 15))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            CircularCheckbox(selected: selected, userLoaded: userLoaded)
                .overlay(self.loadingPosts ? ProgressView() : nil)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if selected {
                selectedUsers.remove(user.id)
            } else {
                self.loadingPosts = true
                mapViewModel.selectAndLoadPostsIfNotLoaded(appState: appState, globalViewState: viewState, user: user) {
                    self.loadingPosts = false
                }
            }
        }
        .contextMenu {
            if !loadingPosts, let num = mapViewModel.numLoadedPostsByUser[user.id], num > 0 {
                loadedPostsInfo
            }
        }
    }
}


struct UserFilter: View {
    @Namespace private var userFilter
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @ObservedObject var mapViewModel: MapViewModelV2
    
    private func userMatchesFilter(user: PublicUser, text: String) -> Bool {
        user.firstName.lowercased().starts(with: text)
        || user.lastName.lowercased().starts(with: text)
        || user.username.lowercased().starts(with: text)
    }
    
    var filteredUsers: [PublicUser] {
        let text = mapViewModel.filterUsersQuery.lowercased()
        guard case let .user(currentUser) = appState.currentUser else {
            return []
        }
        return mapViewModel.allUsers.values
            .filter { user in
                userMatchesFilter(user: user, text: text)
            }
            .sorted { (user1, user2) in
                if user1.id == currentUser.id {
                    return true
                }
                if user2.id == currentUser.id {
                    return false
                }
                let selected1 = mapViewModel.isSelected(userId: user1.id)
                let selected2 = mapViewModel.isSelected(userId: user2.id)
                if selected1 == selected2 {
                    return mapViewModel.sortUsersHelper(user1, user2)
                } else {
                    return selected1
                }
            }
    }
    
    var userSearchResultsWithoutExistingUsers: [PublicUser] {
        let allUserIds = Set(mapViewModel.allUsers.keys)
        return mapViewModel.userSearchResults.filter({ !allUserIds.contains($0.id) })
    }
    
    var existingMapBody: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button("Refresh map") {
                    mapViewModel.refreshMap(appState: appState, globalViewState: globalViewState)
                }
                .foregroundColor(.blue)
                .disabled(mapViewModel.loadStatus == .loading)
                
                Spacer()
                
                if filteredUsers.count > 2 {
                    Button("Select all") {
                        mapViewModel.selectAllUsers()
                    }
                    .foregroundColor(mapViewModel.allUsersSelected ? .gray : .blue)
                    .disabled(mapViewModel.allUsersSelected)

                    Divider()

                    Button("Clear") {
                        mapViewModel.clearUserSelection()
                    }
                    .foregroundColor(mapViewModel.noUsersSelected ? .gray : .blue)
                    .disabled(mapViewModel.noUsersSelected)
                }
            }
            .padding(.bottom, 10)
            
            VStack {
                if filteredUsers.count > 0 {
                    VStack(spacing: 10) {
                        ForEach(filteredUsers) { user in
                            SelectableUser(mapViewModel: mapViewModel, user: user, selectedUsers: $mapViewModel.selectedUsers)
                                .matchedGeometryEffect(id: user.id, in: userFilter)
                        }
                    }
                    .padding(.bottom)
                }
                
                if userSearchResultsWithoutExistingUsers.count > 0 {
                    Text(mapViewModel.allUsers.isEmpty ? "Suggested" : "More users")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(userSearchResultsWithoutExistingUsers) { user in
                        SelectableUser(mapViewModel: mapViewModel, user: user, selectedUsers: $mapViewModel.selectedUsers)
                            .matchedGeometryEffect(id: user.id, in: userFilter)
                    }
                }
            }
            .animation(.easeInOut, value: filteredUsers)
        }
        .font(.system(size: 15))
    }
    
    var body: some View {
        existingMapBody
    }
}
