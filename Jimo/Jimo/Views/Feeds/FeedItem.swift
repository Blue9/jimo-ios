//
//  FeedItem.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/4/22.
//

import SwiftUI

struct FeedItem: View {
    enum Destination: Hashable {
        case post(Post)
        case user(PublicUser)
        case map(Post)

        @ViewBuilder func view() -> some View {
            switch self {
            case let .post(post):
                ViewPost(initialPost: post)
            case let .user(user):
                ProfileScreen(initialUser: user)
            case let .map(post):
                LiteMapView(post: post)
            }
        }
    }

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState

    @StateObject var postVM = PostVM()

    var post: Post
    var navigate: (Destination?) -> Void
    var showShareSheet: () -> Void

    var body: some View {
        VStack {
            PostHeader(postVM: postVM, post: post, navigate: { self.navigate(.user($0)) }, showShareSheet: showShareSheet)

            PostImage(post: post)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                .contentShape(Rectangle())
                .clipped()
                .onTapGesture {
                    self.navigate(.post(post))
                }

            VStack(spacing: 5) {
                PostPlaceName(post: post).onTapGesture {
                    Analytics.track(.postPlaceNameTap)
                    self.navigate(.map(post))
                }
                PostCaption(post: post)
                    .lineLimit(3)
                    .onTapGesture {
                        self.navigate(.post(post))
                    }
            }
            PostFooter(
                viewModel: postVM,
                post: post,
                onCommentTap: { self.navigate(.post(post)) }
            )

            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 8)
                .foregroundColor(Color("foreground").opacity(0.1))
        }
    }
}
