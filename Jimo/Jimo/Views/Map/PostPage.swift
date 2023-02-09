//
//  PostPage.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/17/22.
//

import SwiftUI

struct PostPage: View {
    var post: Post

    @State private var showFullPost = false
    @StateObject private var postViewModel = PostVM()

    @ViewBuilder
    var mainBody: some View {
        HStack(alignment: .top) {
            Group {
                if let url = post.imageUrl {
                    URLImage(url: url, thumbnail: true)
                } else {
                    Image(post.category)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.black.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .padding(40)
                        .background(Color(post.category))
                }
            }
            .frame(width: 120, height: 120)
            .cornerRadius(2)

            VStack(alignment: .leading, spacing: 5) {
                if let stars = post.stars {
                    StarsView(stars: stars)
                }
                Group {
                    Text(post.user.username.lowercased() + " ")
                        .font(.caption)
                        .fontWeight(.bold)
                    +
                    Text(post.content)
                        .font(.caption)
                }

                Spacer()

                HStack(spacing: 5) {
                    MiniPostLikeButton(postViewModel: postViewModel, initialPost: post)
                        .font(.system(size: 15))
                    Text(String(post.likeCount))
                        .font(.caption)
                        .opacity(post.likeCount > 0 ? 1 : 0)

                    Spacer().frame(width: 2)

                    Image(systemName: "bubble.right")
                        .font(.system(size: 15))
                        .offset(y: 1.5)
                    Text(String(post.commentCount))
                        .font(.caption)
                        .opacity(post.likeCount > 0 ? 1 : 0)

                    Spacer()
                }
                .foregroundColor(Color("foreground"))
            }
            .frame(height: 120)
            Spacer()
        }
    }

    var body: some View {
        NavigationLink {
            ViewPost(initialPost: postViewModel.post ?? post, showSaveButton: false)
        } label: {
            mainBody.contentShape(Rectangle())
        }.buttonStyle(NoButtonStyle())
    }
}

private struct StarsView: View {
    var stars: Int

    var body: some View {
        HStack(spacing: 2) {
            if stars == 0 {
                Image(systemName: "star.slash.fill")
                    .foregroundColor(.gray)
            } else {
                ForEach(0..<stars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            if let name = Stars.names[stars] {
                Text("· \(name)").foregroundColor(.gray)
            }
        }
        .font(.caption)
    }
}

private struct MiniPostLikeButton: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState

    @ObservedObject var postViewModel: PostVM

    var initialPost: Post

    var post: Post {
        postViewModel.post ?? initialPost
    }

    private var showFilledHeart: Bool {
        (post.liked || postViewModel.liking) && !postViewModel.unliking
    }

    var body: some View {
        mainBody.onAppear {
            postViewModel.listen(post: post, onDelete: {})
        }
    }

    @ViewBuilder
    var mainBody: some View {
        if showFilledHeart {
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                postViewModel.unlikePost(postId: post.id, appState: appState, viewState: viewState)
            }) {
                Image(systemName: "heart.fill")
            }
            .foregroundColor(.red)
        } else {
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                postViewModel.likePost(postId: post.id, appState: appState, viewState: viewState)
            }) {
                Image(systemName: "heart")
            }
            .foregroundColor(Color("foreground"))
        }
    }
}
