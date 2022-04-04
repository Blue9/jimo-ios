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
    
    var body: some View {
        VStack {
            PostHeader(postVM: postVM, post: post)
            PostCaption(post: post)
                .lineLimit(3)
            
            NavigationLink(destination: fullPostView) {
                PostImage(post: post)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                    .clipped()
            }.buttonStyle(NoButtonStyle())
            
            PostFooter(viewModel: postVM, post: post, showZeroCommentCount: true)
        }
    }
    
    @ViewBuilder var fullPostView: some View {
        LazyView {
            ViewPost(post: post)
        }
    }
}
