//
//  ViewPost.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/5/21.
//

import SwiftUI

class PostDeletionListener: ObservableObject {
    let nc = NotificationCenter.default
    
    var postId: PostId?
    var onDelete: (() -> ())?
    
    func onPostDelete(postId: PostId, onDelete: @escaping () -> ()) {
        if self.postId != nil {
            // already observing
            return
        }
        self.postId = postId
        self.onDelete = onDelete
        nc.addObserver(self, selector: #selector(postDeleted), name: PostPublisher.postDeleted, object: nil)
    }
    
    @objc func postDeleted(notification: Notification) {
        guard let postId = postId, let onDelete = onDelete else {
            return
        }
        let deletedPostId = notification.object as! PostId
        if postId == deletedPostId {
            onDelete()
        }
    }
}

struct ViewPost: View {
    let postDeletionListener = PostDeletionListener()
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var postVM = PostVM()
    @StateObject private var commentsViewModel = CommentsViewModel()
    @State private var initializedComments = false
    @State private var imageSize = CGSize.zero
    
    let post: Post
    var highlightedComment: Comment? = nil
    
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
    
    var postItem: some View {
        VStack {
            PostHeader(postVM: postVM, post: post)
            PostCaption(post: post)
            PostImage(post: post)
                .frame(width: UIScreen.main.bounds.width)
            PostFooter(viewModel: postVM, post: post, showZeroCommentCount: false)
        }
        .onAppear {
            postDeletionListener.onPostDelete(postId: post.id, onDelete: { presentationMode.wrappedValue.dismiss() })
        }
    }
    
    var commentField: some View {
        CommentInputField(
            text: $commentsViewModel.newCommentText,
            submitting: commentsViewModel.creatingComment,
            buttonColor: colorTheme,
            onSubmit: { [weak commentsViewModel] in
                commentsViewModel?.createComment()
                // TODO: Scroll to comment position
            }
        )
    }
    
    @ViewBuilder var mainBody: some View {
        RefreshableScrollView {
            VStack {
                // Post contents
                postItem
                
                // List of comments
                LazyVStack(spacing: 0) {
                    ForEach(commentsViewModel.comments) { comment in
                        ZStack(alignment: .bottom) {
                            CommentItem(commentsViewModel: commentsViewModel, comment: comment, isMyPost: isMyPost)
                            Divider()
                                .foregroundColor(.gray)
                                .padding(.horizontal, 10)
                        }
                        .background(Color("background"))
                    }
                    Color.clear
                        .appear {
                            commentsViewModel.loadMore()
                        }
                }
            }
        } onRefresh: { onFinish in
            commentsViewModel.loadComments(onFinish: onFinish)
        }
        .onAppear {
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
