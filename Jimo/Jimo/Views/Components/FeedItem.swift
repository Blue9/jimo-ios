//
//  FeedItem.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/8/20.
//

import SwiftUI

struct NoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct FeedItemLikes: View {
    @ObservedObject var feedItemVM: FeedItemVM
    var post: Post
    
    private var showFilledHeart: Bool {
        return (post.liked || feedItemVM.liking) && !feedItemVM.unliking
    }
    
    private var likeCount: Int {
        let inc = feedItemVM.liking ? 1 : 0
        let dec = feedItemVM.unliking ? 1 : 0
        return post.likeCount + inc - dec
    }
    
    var body: some View {
        HStack {
            Text(String(likeCount))
                .font(Font.custom(Poppins.regular, size: 14))
                .opacity(likeCount > 0 ? 1 : 0) // Build view regardless to keep height consistent
            
            if showFilledHeart {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    feedItemVM.unlikePost()
                }) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
            } else {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    feedItemVM.likePost()
                }) {
                    Image(systemName: "heart")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct FeedItemBody: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    
    @StateObject var feedItemVM: FeedItemVM
    
    @State private var showPostOptions = false
    @State private var showConfirmDelete = false
    @State private var showConfirmReport = false
    
    @State private var initialized = false
    @State private var relativeTime: String = ""
    
    @State private var viewFullPost = false
    
    var post: Post
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let formatter = RelativeDateTimeFormatter()
    /// If true, the full content is shown and is not tappable. This is used for the view post screen.
    var fullPost = false
    
    func getRelativeTime(post: Post) -> String {
        if Date().timeIntervalSince(post.createdAt) < 1 {
            return "just now"
        }
        return formatter.localizedString(for: post.createdAt, relativeTo: Date())
    }
    
    var isMyPost: Bool {
        if case let .user(user) = appState.currentUser {
            return user.username == post.user.username
        }
        // Should never be here since user should be logged in
        return false
    }
    
    var profileView: some View {
        Profile(profileVM: ProfileVM(appState: appState, globalViewState: globalViewState, user: post.user))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(UIColor(backgroundColor))
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    NavTitle("Profile")
                }
            })
    }
    
    var fullPostView: some View {
        ViewPost(postId: feedItemVM.postId)
    }
    
    var postContent: some View {
        let content = VStack(alignment: .leading) {
            if post.content.count > 0 {
                Text(post.content)
                    .lineLimit(fullPost ? nil : 2)
                    .padding(.top, 10)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, minHeight: 10, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let image = post.imageUrl {
                URLImage(url: image,
                         loading: Image("grayRect").resizable(),
                         failure: Image("imageFail"))
                    .id(post.imageUrl)
                    .frame(minHeight: fullPost ? .zero : 300)
                    .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: fullPost ? .infinity : 300)
                    .cornerRadius(0)
                    .contentShape(Rectangle())
                    .background(Color(post.category))
            }
        }
        
        if !fullPost {
            return AnyView(
                NavigationLink(destination: fullPostView, isActive: $viewFullPost) {
                    content.background(backgroundColor)
                }
                .buttonStyle(NoButtonStyle()))
        } else {
            return AnyView(content.onTapGesture(count: 2) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if post.liked {
                    feedItemVM.unlikePost()
                } else {
                    feedItemVM.likePost()
                }
            })
        }
    }
    
    var postBody: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .frame(height: 32)
                .foregroundColor(Color(post.category))
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    NavigationLink(destination: profileView) {
                        URLImage(
                            url: post.user.profilePictureUrl,
                            loading: Image(systemName: "person.crop.circle"),
                            failure: Image(systemName: "person.crop.circle"))
                            .id(post.user.profilePictureUrl)
                            .foregroundColor(.gray)
                            .background(Color.white)
                            .font(.system(size: 16, weight: .light))
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50, alignment: .center)
                            .cornerRadius(25)
                            .padding(.trailing, 6)
                            .padding(.top, 4)
                    }
                    .buttonStyle(NoButtonStyle())
                    
                    VStack(alignment: .leading) {
                        HStack {
                            NavigationLink(destination: profileView) {
                                Text(post.user.firstName + " " + post.user.lastName)
                                    .font(Font.custom(Poppins.medium, size: 16))
                                    .bold()
                                    .frame(height: 26)
                                    .padding(.trailing, 10)
                            }
                            .buttonStyle(NoButtonStyle())
                            .foregroundColor(.black)
                            .buttonStyle(NoButtonStyle())
                            
                            Spacer()
                            
                            Button(action: { self.showPostOptions = true }) {
                                Image(systemName: "ellipsis")
                                    .font(.subheadline)
                                    .frame(width: 26, height: 26)
                                    .padding(.trailing)
                                    .foregroundColor(.black)
                            }
                        }
                        
                        NavigationLink(destination: MapView(mapModel: appState.mapModel,
                                                            localSettings: appState.localSettings,
                                                            mapViewModel: MapViewModel(appState: appState,
                                                                                       viewState: globalViewState,
                                                                                       preselectedPost: post))
                                        .navigationBarColor(UIColor(backgroundColor))
                                        .toolbar {
                                            ToolbarItem(placement: .principal) {
                                                NavTitle("View Place")
                                            }
                                        }) {
                            HStack {
                                Text(post.place.name).lineLimit(1)
                            }
                            .foregroundColor(.black)
                            .font(Font.custom(Poppins.regular, size: 14))
                            .offset(y: 6)
                        }
                        .buttonStyle(NoButtonStyle())
                    }
                }
                .padding(.leading)
                
                postContent
                    .font(Font.custom(Poppins.regular, size: 14))
                
                HStack {
                    Text(relativeTime)
                        .font(Font.custom(Poppins.regular, size: 12))
                        .foregroundColor(.gray)
                        .onReceive(timer, perform: { _ in
                            relativeTime = getRelativeTime(post: post)
                        })
                    
                    Spacer()
                    
                    FeedItemLikes(feedItemVM: feedItemVM, post: post)
                }
                .padding(.top, 8)
                .padding(.horizontal)
            }
            .padding(.top, 4)
            .padding(.bottom, 6)
            
            if feedItemVM.deleting {
                ProgressView()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                    .background(Color.init(.sRGB, white: 1, opacity: 0.5))
            }
        }
    }
    
    var body: some View {
        postBody
            .background(backgroundColor)
            .onTapGesture {
                viewFullPost = true
            }
            .contextMenu {
                if post.liked {
                    Button(action: { feedItemVM.unlikePost() }) {
                        Text("Unlike")
                    }
                } else {
                    Button(action: { feedItemVM.likePost() }) {
                        Text("Like")
                    }
                }
                
                if isMyPost {
                    Button(action: { showConfirmDelete.toggle() }) {
                        Text("Delete post")
                    }
                } else {
                    Button(action: { showConfirmReport.toggle() }) {
                        Text("Report post")
                    }
                }
            }
            .onAppear {
                if !initialized {
                    relativeTime = getRelativeTime(post: post)
                    feedItemVM.listenToPostUpdates()
                    initialized = true
                }
            }
            /// .appear works slightly differently than onAppear and is more accurate, onAppear is kind of buggy but tends to trigger earlier so faster updates
            .appear {
                feedItemVM.listenToPostUpdates()
            }
            .disappear {
                feedItemVM.stopListeningToPostUpdates()
            }
            .actionSheet(isPresented: $showPostOptions) {
                ActionSheet(
                    title: Text("Post options"),
                    buttons: isMyPost ? [
                        .destructive(Text("Delete"), action: {
                            showConfirmDelete = true
                        }),
                        .cancel()
                    ] : [
                        .default(Text("Report"), action: {
                            showConfirmReport = true
                        }),
                        .cancel()
                    ])
            }
            .alert(isPresented: $showConfirmDelete) {
                Alert(title: Text("Are you sure?"),
                      message: Text("You can't undo this action"),
                      primaryButton: .destructive(Text("Delete post")) {
                        feedItemVM.deletePost()
                      },
                      secondaryButton: .cancel())
            }
            .textAlert(isPresented: $showConfirmReport, title: "Report post",
                       message: "Tell us what's wrong with this post. Please include your email address in case we need to follow up.") { text in
                feedItemVM.reportPost(details: text)
            }
    }
}

struct FeedItem: View {
    @StateObject var feedItemVM: FeedItemVM
    
    var fullPost: Bool = false
    
    var body: some View {
        if let post = feedItemVM.post {
            FeedItemBody(feedItemVM: feedItemVM, post: post, fullPost: fullPost)
        } else {
            EmptyView()
        }
    }
}

struct FeedItem_Previews: PreviewProvider {
    static let api = APIClient()
    static let appState = AppState(apiClient: api)
    
    static let post = Post(
        postId: "test",
        user: PublicUser(
            username: "john",
            firstName: "Johnjohnjohn",
            lastName: "JohnjohnjohnJohnjohnjohnJohnjohnjohn",
            profilePictureUrl: "https://i.imgur.com/ugITQw2.jpg",
            postCount: 100,
            followerCount: 1000000,
            followingCount: 1),
        place: Place(placeId: "place", name: "Kai's Hotdogs This is a very very very very long place name", location: Location(coord: .init(latitude: 0, longitude: 0))),
        category: "food",
        content: "Wow! I really really really like this place. This place is so so so very very good. I really really really like this place. This place is so so so very very good.",
        imageUrl: "https://i.imgur.com/ugITQw2.jpg",
        createdAt: Date(),
        likeCount: 10,
        liked: false,
        customLocation: nil)
    
    static var previews: some View {
        FeedItem(feedItemVM: FeedItemVM(appState: appState, viewState: GlobalViewState(), postId: post.id))
            .environmentObject(appState)
            .environmentObject(GlobalViewState())
    }
}
