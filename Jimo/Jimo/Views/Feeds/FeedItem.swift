//
//  FeedItem.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/4/22.
//

import SwiftUI

struct FeedItem: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState

    @StateObject var postVM = PostVM()

    var post: Post
    var navigate: (NavDestination) -> Void
    var showShareSheet: () -> Void

    var body: some View {
        VStack {
            PostHeader(
                postVM: postVM,
                post: post,
                navigate: { self.navigate(.profile(user: $0)) },
                showShareSheet: showShareSheet
            )

            PostImage(post: post)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                .contentShape(Rectangle())
                .clipped()
                .onTapGesture {
                    self.navigate(.post(post: post))
                }

            VStack(spacing: 5) {
                PostPlaceName(post: post).onTapGesture {
                    Analytics.track(.postPlaceNameTap)
                    self.navigate(.liteMapView(post: post))
                }
                PostCaption(post: post)
                    .lineLimit(3)
                    .onTapGesture {
                        self.navigate(.post(post: post))
                    }
            }
            PostFooter(
                viewModel: postVM,
                post: post,
                onCommentTap: { self.navigate(.post(post: post)) }
            )

            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 8)
                .foregroundColor(Color("foreground").opacity(0.1))
        }
    }
}
