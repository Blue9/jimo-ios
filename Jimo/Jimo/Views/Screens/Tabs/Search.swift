//
//  Search.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/13/20.
//

import SwiftUI
import MapKit
import ASCollectionView
import FirebaseAnalytics

struct Search: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @StateObject var searchViewModel = SearchViewModel()
    @StateObject var discoverViewModel = DiscoverViewModel()
    
    @State private var initialLoadCompleted = false
    
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
    
    @ViewBuilder var discoverFeed: some View {
        if !discoverViewModel.initialized {
            ProgressView().padding(.top, 20)
        } else {
            discoverFeedLoaded
        }
    }
    
    var discoverFeedLoaded: some View {
        ASCollectionView {
            ASCollectionViewSection(id: 0, data: discoverViewModel.posts) { post, _ in
                GeometryReader { geometry in
                    NavigationLink(destination: ViewPost(post: post)) {
                        URLImage(url: post.imageUrl, thumbnail: true)
                            .frame(maxWidth: .infinity)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .background(Color(post.category))
                .cornerRadius(2)
            }
        }
        .alwaysBounceVertical()
        .shouldScrollToAvoidKeyboard(false)
        .layout {
            .grid(
                layoutMode: .fixedNumberOfColumns(3),
                itemSpacing: 2,
                lineSpacing: 2,
                itemSize: .estimated(80),
                sectionInsets: .init(top: 0, leading: 2, bottom: 0, trailing: 2)
            )
        }
        .scrollIndicatorsEnabled(horizontal: false, vertical: false)
        .onPullToRefresh { onFinish in
            discoverViewModel.loadDiscoverPage(appState: appState, onFinish: onFinish)
        }
        .ignoresSafeArea(.keyboard, edges: .all)
    }
    
    var userResults: some View {
        List(searchViewModel.userResults, id: \.username) { (user: PublicUser) in
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
                }
            }
            .listRowBackground(Color("background"))
        }
        .gesture(DragGesture().onChanged { _ in hideKeyboard() })
        .listStyle(PlainListStyle())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(
                    text: $searchViewModel.query,
                    isActive: $searchViewModel.searchBarFocused,
                    placeholder: "Search people",
                    disableAutocorrection: true,
                    onCommit: {}
                )
                .padding(.horizontal)
                .padding(.bottom, 0)
                
                if !searchViewModel.searchBarFocused {
                    discoverFeed
                } else {
                    userResults
                    .appear {
                        print(">>> User performed search")
                        Analytics.logEvent("user_performed_search", parameters: nil)
                    }

                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("background"))
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(UIColor(Color("background")))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NavTitle("Discover")
                }
            }
            .appear {
                if !initialLoadCompleted {
                    initialLoadCompleted = true
                    searchViewModel.listen(appState: appState)
                    discoverViewModel.loadDiscoverPage(appState: appState)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct Search_Previews: PreviewProvider {
    
    static var previews: some View {
        Search()
    }
}
