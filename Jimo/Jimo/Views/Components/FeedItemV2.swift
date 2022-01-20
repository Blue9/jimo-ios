//
//  FeedItemV2.swift
//  Jimo
//
//  Created by Gautam Mekkat on 9/9/21.
//

import SwiftUI
import MapKit

struct FeedItemLikesV2: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @ObservedObject var feedItemVM: FeedItemVM
    let post: Post
    
    private var showFilledHeart: Bool {
        (post.liked || feedItemVM.liking) && !feedItemVM.unliking
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
                .foregroundColor(Color("foreground"))
            }
        }
        .offset(y: 0.5)
    }
}

struct FeedItemCommentsV2: View {
    
    var post: Post
    
    var body: some View {
        Image(systemName: "bubble.right")
            .font(.system(size: 20))
            .foregroundColor(Color("foreground"))
            .offset(y: 1.5)
    }
}

struct FeedItemBodyV2: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @ObservedObject var feedItemVM: FeedItemVM
    @Binding var imageSize: CGSize
    
    @State private var showPostOptions = false
    @State private var showConfirmDelete = false
    @State private var showConfirmReport = false
    
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
    
    @ViewBuilder var profileView: some View {
        LazyView {
            ProfileScreen(initialUser: post.user)
        }
    }
    
    @ViewBuilder var fullPostView: some View {
        LazyView {
            ViewPost(post: post)
        }
    }
    
    @ViewBuilder var profilePicture: some View {
        ZStack {
            URLImage(
                url: post.user.profilePictureUrl,
                loading: Image(systemName: "person.crop.circle"),
                thumbnail: true
            )
                .foregroundColor(.gray)
                .frame(width: 37, height: 37)
                .cornerRadius(23)
        }
    }
    
    @ViewBuilder var pinView: some View {
        LazyView {
            MapViewV2(bottomSheetPosition: .hidden, preselectedPost: post)
        }
    }
    
    var placeName: String {
        if let regionName = post.place.regionName {
            return " · \(post.place.name), \(regionName)"
        } else {
            return " · \(post.place.name)"
        }
    }
    
    @ViewBuilder var header: some View {
        HStack {
            NavigationLink(destination: profileView) {
                profilePicture
            }.buttonStyle(NoButtonStyle())
            
            VStack(alignment: .leading) {
                NavigationLink(destination: profileView) {
                    Text(post.user.username.lowercased())
                        .font(.system(size: 16))
                        .bold()
                        .foregroundColor(Color("foreground"))
                }.buttonStyle(NoButtonStyle())
                
                NavigationLink(destination: pinView) {
                    HStack(spacing: 0) {
                        Text(post.category.capitalized)
                            .foregroundColor(Color(post.category))
                            .bold()
                        Text(placeName)
                    }
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .foregroundColor(Color("foreground"))
                }.buttonStyle(NoButtonStyle())
            }
            
            Spacer()
            
            Button(action: { self.showPostOptions = true }) {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .frame(width: 26, height: 26)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder var footer: some View {
        HStack(spacing: 3) {
            
            FeedItemLikesV2(feedItemVM: feedItemVM, post: post)
            
            Text("\(post.likeCount) like\(post.likeCount != 1 ? "s" : "")")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            Spacer().frame(width: 2)
            
            FeedItemCommentsV2(post: post)
            
            Text("\(post.commentCount) comment\(post.commentCount != 1 ? "s" : "")")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(appState.relativeTime(for: post.createdAt))
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
    }
    
    @ViewBuilder var mapSnapshot: some View {
        MapSnapshotView(post: post, width: UIScreen.main.bounds.width)
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
    }
    
    @ViewBuilder var postContent: some View {
        Group {
            if post.content.count > 0 {
                Text(post.content)
                    .font(.system(size: 13))
                    .foregroundColor(Color("foreground"))
                    .padding(.horizontal)
                    .lineLimit(fullPost ? nil : 3)
                    .frame(maxWidth: .infinity, minHeight: 10, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let url = post.imageUrl {
                URLImage(url: url, imageSize: $imageSize)
                    .frame(width: UIScreen.main.bounds.width)
                    .frame(minHeight: fullPost ? 0 : UIScreen.main.bounds.width,
                           maxHeight: fullPost ? .infinity : UIScreen.main.bounds.width)
                    .contentShape(Rectangle())
                    .clipped()
                    .background(Color(post.category))
            } else if fullPost {
                NavigationLink(destination: pinView) {
                    mapSnapshot
                }.buttonStyle(NoButtonStyle())
            } else {
                mapSnapshot
            }
        }
    }
    
    @ViewBuilder var feedItemBody: some View {
        VStack(alignment: .leading) {
            header
            
            if fullPost {
                postContent
            } else {
                NavigationLink(destination: fullPostView) {
                    postContent
                }.buttonStyle(NoButtonStyle())
            }
            
            footer
                .padding(.horizontal)
        }
        .padding(.bottom, 10)
        .background(Color("background"))
    }
    
    var body: some View {
        feedItemBody
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
                       message: "Tell us what's wrong with this post.") { text in
                feedItemVM.reportPost(postId: post.id, details: text, appState: appState, viewState: globalViewState)
            }
    }
}

struct FeedItemV2: View {
    @State var imageSize = CGSize.zero
    
    let post: Post
    var fullPost: Bool = false
    
    var body: some View {
        TrackedImageFeedItemV2(post: post, fullPost: fullPost, imageSize: $imageSize)
    }
}


struct TrackedImageFeedItemV2: View {
    @StateObject var feedItemVM = FeedItemVM()
    
    let post: Post
    let fullPost: Bool
    
    @Binding var imageSize: CGSize
    
    var body: some View {
        FeedItemBodyV2(feedItemVM: feedItemVM, imageSize: $imageSize, post: post, fullPost: fullPost)
    }
}
