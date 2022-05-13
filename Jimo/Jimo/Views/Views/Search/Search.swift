//
//  Search.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/13/20.
//

import SwiftUI
import MapKit
import ASCollectionView

struct Search: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @StateObject var searchViewModel = SearchViewModel()
    @StateObject var suggestedViewModel = SuggestedUserCarouselViewModel()
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
            if suggestedViewModel.shouldPresent() {
                ASCollectionViewSection(id: 0) {
                    SuggestedUsersCarousel(viewModel: suggestedViewModel)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width / 3 * 1.3)
                        .fixedSize(horizontal: true, vertical: true)
                }.sectionHeader {
                    HStack {
                        Text("Users to follow")
                            .font(.headline)
                            .padding()
                        
                        Spacer()
                    }
                }
            }
            
            ASCollectionViewSection(id: 1, data: discoverViewModel.posts) { post, _ in
                NavigationLink(destination: ViewPost(initialPost: post)) {
                    PostGridCell(post: post)
                }
            }.sectionHeader {
                HStack {
                    Text(discoverViewModel.maybeLocation != nil ? "Suggested posts near you" : "Suggested posts")
                        .font(.headline)
                        .padding()
                    
                    Spacer()
                }
            }
        }
        .alwaysBounceVertical()
        .shouldScrollToAvoidKeyboard(false)
        .layout { sectionID in
            switch sectionID {
            case 0:
                return .list(itemSize: .estimated(80))
            default:
                return .grid(
                    layoutMode: .fixedNumberOfColumns(3),
                    itemSpacing: 2,
                    lineSpacing: 2,
                    itemSize: .estimated(80),
                    sectionInsets: .init(top: 0, leading: 2, bottom: 0, trailing: 2)
                )
            }
        }
        .scrollIndicatorsEnabled(horizontal: false, vertical: false)
        .onPullToRefresh { onFinish in
            suggestedViewModel.load(appState: appState, viewState: globalViewState)
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
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("background"))
            .ignoresSafeArea(.keyboard, edges: .bottom)
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
                    suggestedViewModel.load(appState: appState, viewState: globalViewState)
                    discoverViewModel.loadDiscoverPage(appState: appState)
                }
            }
            .trackScreen(.searchTab)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
