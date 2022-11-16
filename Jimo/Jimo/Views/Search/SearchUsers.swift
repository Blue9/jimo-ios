//
//  SearchUsers.swift
//  Jimo
//
//  Created by admin on 11/15/22.
//

import SwiftUI

struct SearchUsers: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @StateObject var searchViewModel = SearchViewModel()
    @StateObject var suggestedViewModel = SuggestedUserCarouselViewModel()
    @State private var initialized = false
    @FocusState private var searchBarFocused: Bool
    
    let defaultImage: Image = Image(systemName: "person.crop.circle")
    
    func profilePicture(user: User) -> some View {
        URLImage(url: user.profilePictureUrl, loading: defaultImage)
            .frame(width: 40, height: 40, alignment: .center)
            .font(Font.title.weight(.ultraLight))
            .foregroundColor(.gray)
            .background(Color.white)
            .cornerRadius(50)
            .padding(.trailing)
    }
    
    func profileView(user: User) -> some View {
        ProfileScreen(initialUser: user)
    }
    
    var body: some View {
        NavigationView {
            mainBody
                .navigationViewStyle(.stack)
        }
        .accentColor(Color("foreground"))
        .onAppear {
            searchBarFocused = true
            suggestedViewModel.load(appState: appState, viewState: viewState)
        }
    }
    
    var suggestedUsersCarousel: some View {
        SuggestedUsersCarousel(viewModel: suggestedViewModel)
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width / 3 * 1.3)
            .fixedSize(horizontal: true, vertical: true)
    }
    
    var mainBody: some View {
        VStack(spacing: 0) {
            SearchBar(
                text: $searchViewModel.query,
                isActive: $searchBarFocused,
                placeholder: "Search people",
                disableAutocorrection: true,
                onCommit: {}
            )
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            userResults
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("background"))
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(Color("background")))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close", action: { presentationMode.wrappedValue.dismiss() })
            }
        }
        .navigationTitle(Text("Find People"))
        .appear {
            if !initialized {
                searchViewModel.listen(appState: appState)
                initialized = true
            }
        }
        .trackScreen(.searchUsers)
    }
    
    var userResults: some View {
        ScrollView(showsIndicators: false) {
            if searchViewModel.query.isEmpty && suggestedViewModel.shouldPresent() {
                suggestedUsersCarousel
                    .padding(.bottom, 10)
            }
            
            LazyVStack(alignment: .leading) {
                Divider()
                ForEach(searchViewModel.userResults, id: \.username) { (user: PublicUser) in
                    NavigationLink(destination: profileView(user: user)) {
                        HStack {
                            profilePicture(user: user)
                            
                            VStack(alignment: .leading) {
                                Text(user.username)
                                    .font(.system(size: 15))
                                    .bold()
                                Text(user.firstName + " " + user.lastName)
                                    .font(.system(size: 15))
                            }
                            .foregroundColor(Color("foreground"))
                            Spacer()
                            
                            Image(systemName: "arrow.right.circle")
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                    }
                    Divider()
                }
            }
        }
    }
}
