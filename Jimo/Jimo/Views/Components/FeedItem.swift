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
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @ObservedObject var feedItemVM: FeedItemVM
    let post: Post
    
    private var showFilledHeart: Bool {
        return (post.liked || feedItemVM.liking) && !feedItemVM.unliking
    }
    
    private var likeCount: Int {
        post.likeCount
    }
    
    var body: some View {
        HStack {
            if showFilledHeart {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    feedItemVM.unlikePost(postId: post.id, appState: appState, viewState: globalViewState)
                }) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                }
                .foregroundColor(.red)
            } else {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    feedItemVM.likePost(postId: post.id, appState: appState, viewState: globalViewState)
                }) {
                    Image(systemName: "heart")
                        .font(.system(size: 20))
                }
                .foregroundColor(.red)
            }
        }
        .offset(y: 0.5)
    }
}

struct FeedItemComments: View {
    @ObservedObject var feedItemVM: FeedItemVM
    var post: Post
    
    var body: some View {
        Image(systemName: "bubble.right")
            .font(.system(size: 20))
            .foregroundColor(.black)
            .offset(y: 1.5)
    }
}


struct FeedItemBody: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    
    @ObservedObject var feedItemVM: FeedItemVM
    @Binding var imageSize: CGSize
    
    @State private var showPostOptions = false
    @State private var showConfirmDelete = false
    @State private var showConfirmReport = false
    @State private var initialized = false
    @State private var viewFullPost = false
    
    let post: Post
    /// If true, the full content is shown and is not tappable. This is used for the view post screen.
    var fullPost = false
    
    var isMyPost: Bool {
        if case let .user(user) = appState.currentUser {
            return user.username == post.user.username
        }
        // Should never be here since user should be logged in
        return false
    }
    
    var profileView: some View {
        ProfileScreen(initialUser: post.user)
    }
    
    var fullPostView: some View {
        ViewPost(post: post)
    }
    
    @ViewBuilder var postContent: some View {
        let content = VStack(alignment: .leading) {
            if post.content.count > 0 {
                Text(post.content)
                    .lineLimit(fullPost ? nil : 2)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, minHeight: 10, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let image = post.imageUrl {
                URLImage(url: image,
                         loading: Image("grayRect").resizable(),
                         failure: Image("imageFail"),
                         imageSize: $imageSize)
                    .frame(minHeight: fullPost ? .zero : UIScreen.main.bounds.width)
                    .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: fullPost ? .infinity : UIScreen.main.bounds.width)
                    .clipped()
                    .background(Color(post.category))
            }
        }
        .padding(.top, 10)
        
        if !fullPost {
            NavigationLink(destination: fullPostView, isActive: $viewFullPost) {
                content.background(backgroundColor)
            }
            .buttonStyle(NoButtonStyle())
        } else {
            content.onTapGesture(count: 2) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if post.liked {
                    feedItemVM.unlikePost(postId: post.id, appState: appState, viewState: globalViewState)
                } else {
                    feedItemVM.likePost(postId: post.id, appState: appState, viewState: globalViewState)
                }
            }
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
                            failure: Image(systemName: "person.crop.circle"),
                            thumbnail: true
                        )
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
                        
                        NavigationLink(destination: MapView(localSettings: appState.localSettings,
                                                            preselectedPlace: post.place)
                                        .navigationBarColor(UIColor(backgroundColor))
                                        .toolbar {
                                            ToolbarItem(placement: .principal) {
                                                NavTitle("View Place")
                                            }
                                        }) {
                            HStack(spacing: 0) {
                                Text(post.place.name)
                                    .minimumScaleFactor(0.5)
                                    .padding(.trailing, 10)
                            }
                            .lineLimit(1)
                            .foregroundColor(.black)
                            .font(Font.custom(Poppins.regular, size: 14))
                        }
                        .offset(y: 6)
                        .buttonStyle(NoButtonStyle())
                    }
                }
                .padding(.leading)
                
                postContent
                    .font(Font.custom(Poppins.regular, size: 14))
                
                HStack(spacing: 5) {
                    
                    FeedItemLikes(feedItemVM: feedItemVM, post: post)
                    
                    Text("\(post.likeCount) like\(post.likeCount != 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer().frame(width: 4)
                    
                    FeedItemComments(feedItemVM: feedItemVM, post: post)
                    
                    Text("\(post.commentCount) comment\(post.commentCount != 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(appState.dateTimeFormatter.localizedString(for: post.createdAt, relativeTo: Date()))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)
                .padding(.horizontal, 10)
                
            }
            .padding(.top, 4)
            .padding(.bottom, fullPost ? 0 : 6)
            
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
                    Button(action: { feedItemVM.unlikePost(postId: post.id, appState: appState, viewState: globalViewState) }) {
                        Text("Unlike")
                    }
                } else {
                    Button(action: { feedItemVM.likePost(postId: post.id, appState: appState, viewState: globalViewState) }) {
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
                        feedItemVM.deletePost(postId: post.id, appState: appState, viewState: globalViewState)
                      },
                      secondaryButton: .cancel())
            }
            .textAlert(isPresented: $showConfirmReport, title: "Report post",
                       message: "Tell us what's wrong with this post. Please include your email address in case we need to follow up.") { text in
                feedItemVM.reportPost(postId: post.id, details: text, appState: appState, viewState: globalViewState)
            }
    }
}

struct FeedItem: View {
    @State var imageSize = CGSize.zero
    
    let post: Post
    var fullPost: Bool = false
    
    var body: some View {
        TrackedImageFeedItem(post: post, fullPost: fullPost, imageSize: $imageSize)
    }
}

struct TrackedImageFeedItem: View {
    @StateObject var feedItemVM = FeedItemVM()
    
    let post: Post
    let fullPost: Bool
    
    @Binding var imageSize: CGSize
    
    var body: some View {
        FeedItemBody(feedItemVM: feedItemVM, imageSize: $imageSize, post: post, fullPost: fullPost)
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
        commentCount: 10,
        liked: false,
        customLocation: nil)
    
    static var previews: some View {
        FeedItem(post: post)
            .environmentObject(appState)
            .environmentObject(GlobalViewState())
    }
}
