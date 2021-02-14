//
//  Search.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/13/20.
//

import SwiftUI
import MapKit


struct Search: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @StateObject var searchViewModel = SearchViewModel()
    @StateObject var discoverViewModel = DiscoverViewModel()
    
    @State var initialLoadCompleted = false
    
    let defaultImage: Image = Image(systemName: "person.crop.circle")
    
    private var columns: [GridItem] = [
        GridItem(.flexible(minimum: 50), spacing: 10),
        GridItem(.flexible(minimum: 50), spacing: 10),
        GridItem(.flexible(minimum: 50), spacing: 10)
    ]
    
    func profilePicture(user: User) -> some View {
        URLImage(url: user.profilePictureUrl, loading: defaultImage, failure: defaultImage)
            .frame(width: 40, height: 40, alignment: .center)
            .font(Font.title.weight(.ultraLight))
            .foregroundColor(.gray)
            .background(Color.white)
            .cornerRadius(50)
            .padding(.trailing)
    }
    
    func profileView(user: User) -> some View {
        Profile(profileVM: ProfileVM(appState: appState, globalViewState: globalViewState, user: user))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(.white)
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    NavTitle("Profile")
                }
            })
    }
    
    var discoverFeed: some View {
        if !discoverViewModel.initialized {
            return AnyView(ProgressView().padding(.top, 20))
        } else {
            return AnyView(
                RefreshableScrollView(refreshing: $discoverViewModel.refreshing) {
                    LazyVGrid(columns: columns) {
                        ForEach(discoverViewModel.posts) { post in
                            GeometryReader { geometry in
                                NavigationLink(destination: ViewPost(postId: post.postId)) {
                                    URLImage(url: post.imageUrl, loading: Image("grayRect"), failure: Image("grayRect"))
                                        .foregroundColor(.black)
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: geometry.size.width)
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(10)
                        }
                    }.padding(10)
                }
            )
        }
    }
    
    var userResults: some View {
        List(searchViewModel.userResults, id: \.username) { (user: PublicUser) in
            NavigationLink(destination: profileView(user: user)) {
                HStack {
                    profilePicture(user: user)
                    
                    VStack(alignment: .leading) {
                        Text(user.firstName + " " + user.lastName)
                            .font(Font.custom(Poppins.medium, size: 16))
                        Text("@" + user.username)
                            .font(Font.custom(Poppins.regular, size: 14))
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    var placeResults: some View {
        VStack {
            List(searchViewModel.placeResults) { (searchCompletion: MKLocalSearchCompletion) in
                HStack {
                    VStack(alignment: .leading) {
                        Text(searchCompletion.title)
                            .font(Font.custom(Poppins.medium, size: 16))
                        Text(searchCompletion.subtitle)
                            .font(Font.custom(Poppins.regular, size: 14))
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    searchViewModel.selectPlace(appState: appState, completion: searchCompletion)
                }
            }
            .listStyle(PlainListStyle())
            
            if let place = searchViewModel.selectedPlaceResult {
                NavigationLink(destination: ViewPlace(mapItem: place)
                                .navigationBarTitleDisplayMode(.inline)
                                .navigationBarColor(.white)
                                .toolbar {
                                    ToolbarItem(placement: .principal) {
                                        NavTitle("View place")
                                    }
                                },
                               isActive: $searchViewModel.showPlaceResult) {
                    EmptyView()
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchViewModel.query, placeholder: "Search")
                    .padding(.bottom, 0)
                Picker(selection: $searchViewModel.searchType, label: Text("What do you want to search for")) {
                    Text("People").tag(SearchType.people)
                    Text("Places").tag(SearchType.places)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if searchViewModel.query.isEmpty {
                    discoverFeed
                } else if searchViewModel.searchType == .people {
                    userResults
                } else if searchViewModel.searchType == .places {
                    placeResults
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(.white)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NavTitle("Discover")
                }
            }
            .onAppear {
                if !initialLoadCompleted {
                    discoverViewModel.appState = appState
                    searchViewModel.listen(appState: appState)
                    discoverViewModel.loadDiscoverPage(initialLoad: true)
                    discoverViewModel.listenToPostUpdates()
                    initialLoadCompleted = true
                }
            }
        }
    }
}

struct Search_Previews: PreviewProvider {
    
    static var previews: some View {
        Search()
    }
}
