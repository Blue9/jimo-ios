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
    @Environment(\.backgroundColor) var backgroundColor
    @Environment(\.presentationMode) var presentation
    @StateObject private var commentsViewModel = CommentsViewModel()
    @State private var initializedComments = false
    @State private var imageHeight: CGFloat?
    
    let postId: PostId
    var highlightedComment: Comment? = nil
    
    var colorTheme: Color {
        if let post = appState.allPosts.posts[postId] {
            return Color(post.category)
        } else {
            return Color.black
        }
    }
    
    var postItem: some View {
        FeedItem(
            feedItemVM: FeedItemVM(
                appState: appState,
                viewState: globalViewState,
                postId: postId,
                onDelete: { presentation.wrappedValue.dismiss() },
                imageHeight: $imageHeight
            ),
            fullPost: true
        )
        .fixedSize(horizontal: false, vertical: true)
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
            ASCollectionViewSection(id: 0) {
                postItem
            }
            
            ASCollectionViewSection(id: 1, data: commentsViewModel.comments, dataID: \.id) { comment, _ in
                ZStack(alignment: .bottom) {
                    CommentItem(commentsViewModel: commentsViewModel, comment: comment)
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
        .shouldInvalidateLayoutOnStateChange(true, animated: false)
        .layout { sectionId in
            switch sectionId {
            case 0: // post
                return .list(itemSize: .estimated(imageHeight ?? 1080), spacing: 0)
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
                commentsViewModel.postId = postId
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
        state.allPosts.posts[post.postId] = post
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
        ViewPost(postId: post.postId)
            .environmentObject(appState)
            .environmentObject(GlobalViewState())
    }
}
