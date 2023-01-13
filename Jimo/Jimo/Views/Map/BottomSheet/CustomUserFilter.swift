//
//  CustomUserFilter.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/10/23.
//

import SwiftUI
import Combine

struct CustomUserFilter: View {
    @Namespace private var userFilter
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @ObservedObject var viewModel: UserFilterViewModel
    
    @FocusState private var isSearchFocused: Bool
    
    var onSubmit: (Set<UserId>) -> ()
    var onDismiss: () -> ()
    
    private func userMatchesFilter(user: PublicUser, text: String) -> Bool {
        user.firstName.lowercased().starts(with: text)
        || user.lastName.lowercased().starts(with: text)
        || user.username.lowercased().starts(with: text)
    }
    
    var filteredUsers: [PublicUser] {
        guard case let .user(currentUser) = appState.currentUser else {
            return []
        }
        return viewModel.loadedUsers.values
            .filter { user in
                userMatchesFilter(user: user, text: viewModel.query.lowercased())
            }
            .sorted { (user1, user2) in
                if user1.id == currentUser.id {
                    return true
                }
                if user2.id == currentUser.id {
                    return false
                }
                let selected1 = viewModel.isSelected(userId: user1.id)
                let selected2 = viewModel.isSelected(userId: user2.id)
                if selected1 == selected2 {
                    return viewModel.sortUsersHelper(user1, user2)
                } else {
                    return selected1
                }
            }
    }
    
    var userSearchResultsWithoutExistingUsers: [PublicUser] {
        let allUserIds = Set(viewModel.loadedUsers.keys)
        return viewModel.userSearchResults.filter({ !allUserIds.contains($0.id) })
    }
    
    var userFilterBody: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                if filteredUsers.count > 0 {
                    VStack(spacing: 10) {
                        ForEach(filteredUsers) { user in
                            SelectableUser(viewModel: viewModel, user: user)
                                .matchedGeometryEffect(id: user.id, in: userFilter)
                        }
                    }
                    .padding(.bottom)
                }
                
                if userSearchResultsWithoutExistingUsers.count > 0 {
                    Text(viewModel.loadedUsers.isEmpty ? "Suggested" : "More people")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(userSearchResultsWithoutExistingUsers) { user in
                        SelectableUser(viewModel: viewModel, user: user)
                            .matchedGeometryEffect(id: user.id, in: userFilter)
                    }
                }
            }
            .animation(.easeInOut, value: filteredUsers)
        }
        .font(.system(size: 15))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                MapSearchField(
                    text: $viewModel.query,
                    isActive: $isSearchFocused,
                    onCommit: {}
                ).padding(.horizontal, 10)
                
                userFilterBody
                    .padding(.horizontal, 10)
                    .onAppear {
                        viewModel.listenToSearchQuery(appState: appState, viewState: globalViewState)
                    }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(UIColor(Color("background")))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NavTitle("Custom")
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        self.onDismiss()
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark").foregroundColor(Color("foreground"))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        self.onSubmit(self.viewModel.selectedUsers)
                        self.dismiss()
                    } label: {
                        Text("Apply").bold()
                    }
                }
            }
        }.navigationViewStyle(.stack)
    }
}

fileprivate struct SelectableUser: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    
    @ObservedObject var viewModel: UserFilterViewModel
    
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
            
            CircularCheckbox(selected: viewModel.isSelected(userId: user.id))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.toggleUser(user: user)
        }
    }
}

class UserFilterViewModel: ObservableObject {
    private var cancelBag: Set<AnyCancellable> = []
    
    @Published var query = ""
    @Published var loadedUsers: [UserId: PublicUser] = [:]
    @Published var selectedUsers: Set<UserId> = []
    @Published var userSearchResults: [PublicUser] = []
    
    func isSelected(userId: UserId) -> Bool {
        selectedUsers.contains(userId)
    }
    
    func sortUsersHelper(_ user1: PublicUser, _ user2: PublicUser) -> Bool {
        user1.username.caseInsensitiveCompare(user2.username) == .orderedAscending
    }
    
    func toggleUser(user: PublicUser) {
        if selectedUsers.contains(user.id) {
            selectedUsers.remove(user.id)
        } else {
            selectedUsers.insert(user.id)
        }
    }
    
    func listenToSearchQuery(appState: AppState, viewState: GlobalViewState) {
        $query
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.search(appState: appState, query: query)
            }
            .store(in: &cancelBag)
    }
    
    private func search(appState: AppState, query: String) {
        appState.searchUsers(query: query)
            .catch { error -> AnyPublisher<[PublicUser], Never> in
                print("Error when searching", error)
                return Empty().eraseToAnyPublisher()
            }
            .sink { [weak self] results in
                self?.userSearchResults = results
                for user in results {
                    self?.loadedUsers[user.id] = user
                }
            }
            .store(in: &cancelBag)
    }
}

fileprivate struct CircularCheckbox: View {
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
