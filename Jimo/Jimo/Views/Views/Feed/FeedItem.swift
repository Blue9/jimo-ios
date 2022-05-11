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
    @Binding var showFullPost: PostId?
    
    var body: some View {
        VStack {
            PostHeader(postVM: postVM, post: post)
            
            PostImage(post: post)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                .contentShape(Rectangle())
                .clipped()
                .onTapGesture {
                    showFullPost = post.id
                }
            
            VStack(spacing: 5) {
                PostPlaceName(post: post)
                PostCaption(post: post)
                    .lineLimit(3)
                    .onTapGesture {
                        showFullPost = post.id
                    }
            }
            PostFooter(viewModel: postVM, post: post, showZeroCommentCount: false, onCommentTap: { showFullPost = post.id })
            
            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 8)
                .foregroundColor(Color("foreground").opacity(0.1))
        }
    }
}
