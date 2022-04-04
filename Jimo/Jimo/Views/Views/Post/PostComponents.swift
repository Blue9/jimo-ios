//
//  PostComponents.swift
//  Jimo
//
//  Created by Gautam Mekkat on 9/9/21.
//

import SwiftUI
import MapKit

struct PostLikeButton: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @ObservedObject var postVM: PostVM
    let post: Post
    
    private var showFilledHeart: Bool {
        (post.liked || postVM.liking) && !postVM.unliking
    }
    
    private var likeCount: Int {
        post.likeCount
    }
    
    var body: some View {
        HStack {
            if showFilledHeart {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    postVM.unlikePost(postId: post.id, appState: appState, viewState: globalViewState)
                }) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                }
                .foregroundColor(.red)
            } else {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    postVM.likePost(postId: post.id, appState: appState, viewState: globalViewState)
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

struct PostCommentsIcon: View {
    var body: some View {
        Image(systemName: "bubble.right")
            .font(.system(size: 20))
            .foregroundColor(Color("foreground"))
            .offset(y: 1.5)
    }
}

struct PostHeader: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @ObservedObject var postVM: PostVM
    
    var post: Post
    
    @State private var showPostOptions = false
    @State private var showConfirmDelete = false
    @State private var showConfirmReport = false
    
    var isMyPost: Bool {
        if case let .user(user) = appState.currentUser {
            return user.username == post.user.username
        }
        // Should never be here since user should be logged in
        return false
    }
    
    var placeName: String {
        if let regionName = post.place.regionName {
            return " · \(post.place.name), \(regionName)"
        } else {
            return " · \(post.place.name)"
        }
    }
    
    var body: some View {
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
                    .frame(height: 26)
            }
        }
        .padding(.horizontal, 10)
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
                    postVM.deletePost(postId: post.id, appState: appState, viewState: globalViewState)
                  },
                  secondaryButton: .cancel())
        }
        .textAlert(isPresented: $showConfirmReport, title: "Report post",
                   message: "Tell us what's wrong with this post.") { text in
            postVM.reportPost(postId: post.id, details: text, appState: appState, viewState: globalViewState)
        }
    }
    
    @ViewBuilder var profileView: some View {
        LazyView {
            ProfileScreen(initialUser: post.user)
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
            LiteMapView(post: post)
        }
    }
}

struct PostCaption: View {
    var post: Post
    
    var body: some View {
        if post.content.count > 0 {
            Text(post.content)
                .font(.system(size: 13))
                .foregroundColor(Color("foreground"))
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 10, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PostImage: View {
    var post: Post
    
    var body: some View {
        ZStack {
            if let url = post.imageUrl {
                URLImage(url: url)
            } else {
                mapSnapshot
            }
        }
    }
    
    @ViewBuilder var mapSnapshot: some View {
        MapSnapshotView(post: post, width: UIScreen.main.bounds.width)
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
    }
}

struct PostFooter: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: PostVM
    var post: Post
    var showZeroCommentCount: Bool
    
    var body: some View {
        HStack(spacing: 3) {
            PostLikeButton(postVM: viewModel, post: post)
            Spacer().frame(width: 2)
            PostCommentsIcon()
            Group {
                if post.commentCount == 0 && showZeroCommentCount {
                    Text("Add a comment")
                } else {
                    Text("\(post.commentCount) comment\(post.commentCount != 1 ? "s" : "")")
                }
            }
            .font(.system(size: 11))
            .foregroundColor(.gray)
            
            Spacer()
            
            Text(appState.relativeTime(for: post.createdAt))
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 10)
    }
    
}
