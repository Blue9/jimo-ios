//
//  UserFilter.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/7/22.
//

import SwiftUI

struct CircularCheckbox: View {
    var selected: Bool
    
    var imageName: String {
        selected ? "checkmark.circle.fill" : "circle"
    }
    
    var body: some View {
        Image(systemName: imageName)
            .font(.system(size: 30, weight: .light))
            .foregroundColor(.blue)
    }
}


struct GlobalViewSelector: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    
    @ObservedObject var mapViewModel: MapViewModelV2
    
    @ViewBuilder var logoImage: some View {
        Image("logo")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .padding(5)
            .overlay(
                Circle()
                    .stroke(Colors.angularGradient, style: StrokeStyle(lineWidth: 2.5))
                    .frame(width: 37.5, height: 37.5)
            )
    }
    
    var body: some View {
        HStack {
            logoImage
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color("foreground").opacity(0.8))
                .frame(width: 40, height: 40)
            
            Text("Community")
                .bold()
                .font(.system(size: 15))
                .lineLimit(1)
            
            Spacer()
            
            CircularCheckbox(selected: mapViewModel.globalSelected)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            mapViewModel.toggleGlobal()
        }
    }
}


struct FollowingViewSelector: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    
    @ObservedObject var mapViewModel: MapViewModelV2
    
    var body: some View {
        HStack {
            Image(systemName: "person.2.circle")
                .resizable()
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color("foreground").opacity(0.8))
                .frame(width: 40, height: 40)
            
            HStack(spacing: 5) {
                Text("All Friends")
                    .bold()
            }
            .font(.system(size: 15))
            .lineLimit(1)
            
            Spacer()
            
            CircularCheckbox(selected: mapViewModel.followingSelected)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            mapViewModel.toggleFollowing()
        }
    }
}


struct SelectableUser: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    
    @ObservedObject var mapViewModel: MapViewModelV2
    var user: PublicUser
    
    var isCurrentUser: Bool {
        if case let .user(currentUser) = appState.currentUser {
            return currentUser.id == user.id
        }
        return false
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
            
            CircularCheckbox(selected: mapViewModel.isSelected(userId: user.id))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            mapViewModel.toggleUser(user: user)
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
        let text = mapViewModel.searchUsersQuery.lowercased()
        guard case let .user(currentUser) = appState.currentUser else {
            return []
        }
        return mapViewModel.loadedUsers.values
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
        let allUserIds = Set(mapViewModel.loadedUsers.keys)
        return mapViewModel.userSearchResults.filter({ !allUserIds.contains($0.id) })
    }
    
    var existingMapBody: some View {
        VStack(spacing: 0) {
            VStack {
                if filteredUsers.count > 0 {
                    VStack(spacing: 10) {
                        GlobalViewSelector(mapViewModel: mapViewModel)
                        FollowingViewSelector(mapViewModel: mapViewModel)
                        
                        ForEach(filteredUsers) { user in
                            SelectableUser(mapViewModel: mapViewModel, user: user)
                                .matchedGeometryEffect(id: user.id, in: userFilter)
                        }
                    }
                    .padding(.bottom)
                }
                
                if userSearchResultsWithoutExistingUsers.count > 0 {
                    Text(mapViewModel.loadedUsers.isEmpty ? "Suggested" : "More people")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(userSearchResultsWithoutExistingUsers) { user in
                        SelectableUser(mapViewModel: mapViewModel, user: user)
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
