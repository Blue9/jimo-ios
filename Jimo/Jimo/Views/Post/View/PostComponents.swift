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
    var post: Post

    private var showFilledHeart: Bool {
        (post.liked || postVM.liking) && !postVM.unliking
    }

    private var likeCount: Int {
        post.likeCount
    }

    @ViewBuilder
    var icon: some View {
        HStack {
            if showFilledHeart {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
            } else {
                Image(systemName: "heart")
                    .font(.system(size: 20))
                    .foregroundColor(Color("foreground"))
            }
        }
        .offset(y: 0.5)
    }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if showFilledHeart {
                postVM.unlikePost(postId: post.id, appState: appState, viewState: globalViewState)
            } else {
                postVM.likePost(postId: post.id, appState: appState, viewState: globalViewState)
            }
        } label: {
            HStack {
                icon
                Text("Like").font(.system(size: 12))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
        }
    }
}

struct PostSaveButton: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState

    @ObservedObject var postVM: PostVM
    var post: Post

    @ViewBuilder
    var icon: some View {
        if post.saved {
            Image(systemName: "bookmark.fill")
                .resizable()
                .frame(width: 16, height: 21)
                .foregroundColor(Color("foreground"))
        } else {
            Image(systemName: "bookmark")
                .resizable()
                .frame(width: 16, height: 21)
                .foregroundColor(Color("foreground"))
        }
    }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if post.saved {
                postVM.unsavePlace(placeId: post.place.placeId, appState: appState, viewState: globalViewState)
            } else {
                postVM.savePlace(placeId: post.place.id, appState: appState, viewState: globalViewState)
            }
        } label: {
            HStack {
                icon
                Text("Save Place").font(.system(size: 12))
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
        }
    }
}

struct PostCommentsIcon: View {
    var post: Post
    var showZeroCommentCount: Bool

    var onTap: (() -> Void)?

    var label: some View {
        HStack {
            Image(systemName: "bubble.right")
                .font(.system(size: 20))
                .foregroundColor(Color("foreground"))
                .offset(y: 1.5)
            Text("Comment").font(.system(size: 12))
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
    }

    var body: some View {
        if let onTap = onTap {
            Button {
                onTap()
            } label: {
                label
            }
        } else {
            label
        }
    }
}

struct PostHeader: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @StateObject var editorVM = CreatePostVM()
    @ObservedObject var postVM: PostVM

    var post: Post

    @State private var showPostOptions = false

    @State private var showEditSheet = false
    @State private var showConfirmDelete = false
    @State private var showConfirmReport = false
    var navigate: (PublicUser) -> Void

    var isMyPost: Bool {
        if case let .user(user) = appState.currentUser {
            return user.username == post.user.username
        }
        // Should never be here since user should be logged in
        return false
    }

    var body: some View {
        HStack {
            profilePicture.onTapGesture {
                self.navigate(post.user)
            }

            VStack(alignment: .leading) {
                Text(post.user.username.lowercased())
                    .font(.system(size: 16))
                    .bold()
                    .foregroundColor(Color("foreground"))
                    .onTapGesture {
                        self.navigate(post.user)
                    }

                HStack(spacing: 0) {
                    Text(post.category.capitalized)
                        .foregroundColor(Color(post.category))
                        .bold()
                    Text(" · ")
                        .foregroundColor(.gray)
                    Text(appState.relativeTime(for: post.createdAt))
                        .foregroundColor(.gray)
                }
                .font(.system(size: 12))
                .lineLimit(1)
            }

            Spacer()

            Button(action: { self.showPostOptions = true }) {
                if globalViewState.showShareOverlay {
                    ProgressView()
                        .padding(.horizontal, 10)
                } else {
                    Image(systemName: "ellipsis")
                        .font(.subheadline)
                        .frame(height: 26)
                        .padding(.horizontal, 10)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.leading, 10)
        .sheet(isPresented: $showEditSheet) {
            CreatePostWithModel(createPostVM: editorVM, presented: $showEditSheet)
                .onAppear {
                    editorVM.initAsEditor(post)
                }
        }
        .actionSheet(isPresented: $showPostOptions) {
            ActionSheet(
                title: Text("Post options"),
                buttons: isMyPost ? [
                    .default(Text("Share"), action: {
                        globalViewState.showShareOverlay(for: .post(post))
                    }),
                    .default(Text("Edit"), action: {
                        showEditSheet = true
                    }),
                    .destructive(Text("Delete"), action: {
                        showConfirmDelete = true
                    }),
                    .cancel()
                ] : [
                    .default(Text("Share"), action: {
                        globalViewState.showShareOverlay(for: .post(post))
                    }),
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
}

struct PostPlaceName: View {
    var post: Post

    var placeName: String {
        if let city = post.place.city {
            return "\(post.place.name), \(city)"
        } else {
            return post.place.name
        }
    }

    var body: some View {
        Text(placeName)
            .font(.system(size: 16))
            .bold()
            .foregroundColor(Color("foreground"))
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
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
        } else {
            Spacer().frame(height: 5)
        }
    }
}

struct PostImage: View {
    var post: Post

    @State private var imageSize: CGSize?

    var body: some View {
        PostImageTrackedSize(post: post, imageSize: $imageSize)
    }
}

struct PostImageTrackedSize: View {
    var post: Post

    @Binding var imageSize: CGSize?

    var body: some View {
        ZStack {
            if let url = post.imageUrl {
                URLImage(url: url, imageSize: $imageSize)
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
    var showSaveButton = true
    var showZeroCommentCount: Bool

    var onCommentTap: (() -> Void)?

    var likeCountText: String {
        return "like".plural(post.likeCount)
    }

    var commentCountText: String {
        return "comment".plural(post.commentCount)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(likeCountText) · \(commentCountText)").font(.caption)
                .padding(.horizontal, 10)

            HStack(spacing: 0) {
                PostLikeButton(postVM: viewModel, post: post)
                Divider().padding(.vertical, 5)
                PostCommentsIcon(post: post, showZeroCommentCount: showZeroCommentCount, onTap: onCommentTap)
                if showSaveButton {
                    Divider().padding(.vertical, 5)
                    PostSaveButton(postVM: viewModel, post: post)
                }
            }
        }
    }
}
