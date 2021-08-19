//
//  ViewPost.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/5/21.
//

import SwiftUI
import ASCollectionView

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
    @Environment(\.backgroundColor) var backgroundColor
    @Environment(\.presentationMode) var presentationMode
    
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
        TrackedImageFeedItem(post: post, fullPost: true, imageSize: $imageSize)
            .fixedSize(horizontal: false, vertical: true)
            .onAppear {
                postDeletionListener.onPostDelete(postId: post.id, onDelete: { presentationMode.wrappedValue.dismiss() })
            }
    }
    
    var commentField: some View {
        CommentInputField(text: $commentsViewModel.newCommentText, buttonColor: colorTheme, onSubmit: { [weak commentsViewModel] in
            commentsViewModel?.createComment()
        })
        .overlay(ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .opacity(commentsViewModel.creatingComment ? 1 : 0))
    }
    
    var body: some View {
        ASCollectionView {
            ASCollectionViewSection(id: imageSize == .zero ? 0 : -1) {
                postItem
            }
            
            ASCollectionViewSection(id: 1, data: commentsViewModel.comments) { comment, _ in
                ZStack(alignment: .bottom) {
                    CommentItem(commentsViewModel: commentsViewModel, comment: comment, isMyPost: isMyPost)
                    Divider().padding(.horizontal, 10)
                }
                .background(backgroundColor)
                .fixedSize(horizontal: false, vertical: true)
            }
            .sectionHeader {
                commentField
            }
            .sectionFooter {
                VStack {
                    if commentsViewModel.loadingComments {
                        ProgressView()
                    }
                    Spacer().frame(height: 150)
                }
                .padding(.top, 20)
            }
        }
        .backgroundColor(UIColor(backgroundColor))
        .shouldScrollToAvoidKeyboard(true)
        .layout { sectionId in
            switch sectionId {
            case 0: // post
                return .list(itemSize: .estimated(300), spacing: 0)
            default:
                return .list(itemSize: .estimated(50), spacing: 0)
            }
        }
        .alwaysBounceVertical()
        .onReachedBoundary { boundary in
            if boundary == .bottom {
                commentsViewModel.loadMore()
            }
        }
        .scrollIndicatorsEnabled(horizontal: false, vertical: false)
        .onPullToRefresh { onFinish in
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
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(backgroundColor))
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                NavTitle("View Post")
            }
        })
    }
}


struct ViewPost_Previews: PreviewProvider {
    static let user = PublicUser(
        username: "gautam",
        firstName: "Gautam",
        lastName: "Mekkat",
        profilePictureUrl: nil,
        postCount: 20,
        followerCount: 20,
        followingCount: 20
    )
    static let api = APIClient()
    static let appState: AppState = {
        let state = AppState(apiClient: api)
        state.currentUser = .user(user)
        return state
    }()
    static let post = Post(
        postId: "test",
        user: PublicUser(
            username: "john",
            firstName: "Johnjohnjohn",
            lastName: "JohnjohnjohnJohnjohnjohnJohnjohnjohn",
            profilePictureUrl: "https://i.imgur.com/ugITQw2.jpg",
            postCount: 100,
            followerCount: 1000000,
            followingCount: 1),
        place: Place(placeId: "place", name: "Kai's Hotdogs This is a very very very very long place name", location: Location(coord: .init(latitude: 0, longitude: 0))),
        category: "food",
        content: "Wow! I really really really like this place. This place is so so so very very good. I really really really like this place. This place is so so so very very good.",
        imageUrl: nil, // "https://i.imgur.com/ugITQw2.jpg",
        createdAt: Date(),
        likeCount: 10,
        commentCount: 10,
        liked: false,
        customLocation: nil)
    
    static var previews: some View {
        ViewPost(post: post)
            .environmentObject(appState)
            .environmentObject(GlobalViewState())
    }
}
