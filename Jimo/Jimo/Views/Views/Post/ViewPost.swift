//
//  ViewPost.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/5/21.
//

import SwiftUI
import ASCollectionView

struct ViewPost: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var postVM = PostVM()
    @StateObject private var commentsViewModel = CommentsViewModel()
    @State private var initializedComments = false
    
    @State private var imageSize: CGSize?
    @State private var scrollPosition: ASCollectionViewScrollPosition?
    
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
            PostFooter(viewModel: postVM, post: post, showZeroCommentCount: true)
                .padding(.bottom, 10)
        }
        .onAppear {
            postVM.listen(post: post, onDelete: { presentationMode.wrappedValue.dismiss() })
        }
    }
    
    var commentField: some View {
        CommentInputField(
            text: $commentsViewModel.newCommentText,
            submitting: commentsViewModel.creatingComment,
            buttonColor: colorTheme,
            onSubmit: { [weak commentsViewModel] in
                commentsViewModel?.createComment()
                // TODO: scroll to new comment
            }
        )
    }
    
    @ViewBuilder var mainBody: some View {
        ASCollectionView {
            ASCollectionViewSection(id: imageSize == nil ? 0 : 1, data: [post], dataID: \.self) { post, _ in
                postItem(post: post)
                    .frame(width: UIScreen.main.bounds.width)
                    .fixedSize()
            }
            
            ASCollectionViewSection(id: 2, data: commentsViewModel.comments) { comment, _ in
                ZStack(alignment: .bottom) {
                    CommentItem(commentsViewModel: commentsViewModel, comment: comment, isMyPost: isMyPost)
                    Divider()
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                }
                .frame(width: UIScreen.main.bounds.width)
                .fixedSize()
                .background(Color("background"))
            }.sectionFooter {
                VStack {
                    if commentsViewModel.loadingComments {
                        ProgressView()
                    }
                    Spacer().frame(height: 150)
                }
                .padding(.top, 20)
            }
        }
        .shouldScrollToAvoidKeyboard(false)
        .alwaysBounceVertical()
        .onReachedBoundary { boundary in
            if boundary == .bottom {
                commentsViewModel.loadMore()
            }
        }
        .layout(interSectionSpacing: 0) { sectionID in
            switch sectionID {
            case 2: // Comments
                return .list(itemSize: .estimated(50), spacing: 0)
            default:
                return .list(itemSize: .estimated(50))
            }
        }
        .onScroll { (point, size) in
            hideKeyboard()
        }
        .scrollPositionSetter($scrollPosition)
        .scrollIndicatorsEnabled(horizontal: false, vertical: false)
        .onPullToRefresh { onFinish in
            commentsViewModel.loadComments(onFinish: onFinish)
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
