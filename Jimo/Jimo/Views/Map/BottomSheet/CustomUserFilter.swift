//
//  CustomUserFilter.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/10/23.
//

import SwiftUI

//struct CustomUserFilter: View {
//    @Namespace private var userFilter
//    @EnvironmentObject var appState: AppState
//    @EnvironmentObject var globalViewState: GlobalViewState
//    @StateObject var viewModel = ViewModel()
//    
//    private func userMatchesFilter(user: PublicUser, text: String) -> Bool {
//        user.firstName.lowercased().starts(with: text)
//        || user.lastName.lowercased().starts(with: text)
//        || user.username.lowercased().starts(with: text)
//    }
//    
//    var filteredUsers: [PublicUser] {
//        let text = viewModel.query.lowercased()
//        guard case let .user(currentUser) = appState.currentUser else {
//            return []
//        }
//        return mapViewModel.loadedUsers.values
//            .filter { user in
//                userMatchesFilter(user: user, text: text)
//            }
//            .sorted { (user1, user2) in
//                if user1.id == currentUser.id {
//                    return true
//                }
//                if user2.id == currentUser.id {
//                    return false
//                }
//                let selected1 = mapViewModel.isSelected(userId: user1.id)
//                let selected2 = mapViewModel.isSelected(userId: user2.id)
//                if selected1 == selected2 {
//                    return mapViewModel.sortUsersHelper(user1, user2)
//                } else {
//                    return selected1
//                }
//            }
//    }
//    
//    var userSearchResultsWithoutExistingUsers: [PublicUser] {
//        let allUserIds = Set(mapViewModel.loadedUsers.keys)
//        return mapViewModel.userSearchResults.filter({ !allUserIds.contains($0.id) })
//    }
//    
//    var existingMapBody: some View {
//        VStack(spacing: 0) {
//            VStack(spacing: 10) {
//                if filteredUsers.count > 0 {
//                    VStack(spacing: 10) {
//                        ForEach(filteredUsers) { user in
//                            SelectableUser(mapViewModel: mapViewModel, user: user)
//                                .matchedGeometryEffect(id: user.id, in: userFilter)
//                        }
//                    }
//                    .padding(.bottom)
//                }
//                
//                if userSearchResultsWithoutExistingUsers.count > 0 {
//                    Text(mapViewModel.loadedUsers.isEmpty ? "Suggested" : "More people")
//                        .font(.system(size: 15, weight: .medium))
//                        .foregroundColor(.gray)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    ForEach(userSearchResultsWithoutExistingUsers) { user in
//                        SelectableUser(mapViewModel: mapViewModel, user: user)
//                            .matchedGeometryEffect(id: user.id, in: userFilter)
//                    }
//                }
//            }
//            .animation(.easeInOut, value: filteredUsers)
//        }
//        .font(.system(size: 15))
//    }
//    
//    var body: some View {
//        existingMapBody
//    }
//}
//
//extension CustomUserFilter {
//    class ViewModel: ObservableObject {
//        @Published var query = ""
//        
//    }
//}
