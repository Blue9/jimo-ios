//
//  ViewPost.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/5/21.
//

import SwiftUI

struct ViewPost: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var postVM = PostVM()
    @StateObject private var commentsViewModel = ViewPostCommentsViewModel()
    @State private var initializedComments = false
    
    @State private var imageSize: CGSize?
    @FocusState private var commentFieldFocused: Bool
    var focusOnAppear = false
    
    let initialPost: Post
    var highlightedComment: Comment? = nil
    
    var post: Post {
        postVM.post ?? initialPost
    }
    
    var colorTheme: Color {
        return Color(post.category)
    }
    
    var isMyPost: Bool {
        if case let .user(user) = appState.currentUser {
            return user.username == post.user.username
        }
        // Should never be here since user should be logged in
        return false
    }
    
    @ViewBuilder
    private func postItem(post: Post) -> some View {
        VStack {
            PostHeader(postVM: postVM, post: post)
            PostImageTrackedSize(post: post, imageSize: $imageSize)
                .frame(width: UIScreen.main.bounds.width)
            VStack(spacing: 5) {
                PostPlaceName(post: post)
                PostCaption(post: post)
            }
            PostFooter(viewModel: postVM, post: post, showZeroCommentCount: true, onCommentTap: {
                commentFieldFocused = true
            }).padding(.bottom, 10)
        }
        .onAppear {
            postVM.listen(post: post, onDelete: { presentationMode.wrappedValue.dismiss() })
        }
    }
    
    var commentField: some View {
        CommentInputField(
            text: $commentsViewModel.newCommentText,
            isFocused: $commentFieldFocused,
            submitting: commentsViewModel.creatingComment,
            buttonColor: colorTheme,
            onSubmit: { [weak commentsViewModel] in
                commentsViewModel?.createComment()
                // TODO: scroll to new comment
            }
        )
        .onAppear {
            if focusOnAppear {
                commentFieldFocused = true
            }
        }
    }
    
    @ViewBuilder var mainBody: some View {
        RefreshableScrollView {
            postItem(post: post)
            
            LazyVStack(spacing: 0) {
                ForEach(commentsViewModel.comments) { comment in
                    ZStack(alignment: .bottom) {
                        CommentItem(commentsViewModel: commentsViewModel, comment: comment, isMyPost: isMyPost)
                        Divider()
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                    }
                    .frame(width: UIScreen.main.bounds.width)
                    .fixedSize()
                    .background(Color("background"))
                }
            }
            .padding(.bottom, 30)
        } onRefresh: { onFinish in
            commentsViewModel.loadComments(onFinish: onFinish)
        } onLoadMore: {
            commentsViewModel.loadMore()
        }
        .onAppear {
            postVM.listen(post: post, onDelete: { presentationMode.wrappedValue.dismiss() })
            if !initializedComments {
                initializedComments = true
                commentsViewModel.highlightedComment = highlightedComment
                commentsViewModel.postId = post.postId
                commentsViewModel.appState = appState
                commentsViewModel.viewState = globalViewState
                commentsViewModel.loadComments()
            }
        }
    }
    
    var body: some View {
        ZStack {
            mainBody
            VStack(spacing: 0) {
                Spacer()
                Divider()
                commentField
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(Color("background")))
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                NavTitle("View Post")
            }
        })
        .trackScreen(.postView)
    }
}
