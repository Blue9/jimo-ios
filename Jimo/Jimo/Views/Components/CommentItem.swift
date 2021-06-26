//
//  CommentItem.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/8/21.
//

import SwiftUI

struct CommentItemLikeButton: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    
    @ObservedObject var singleCommentVM: SingleCommentVM
    @State var comment: Comment
    
    private var likeCount: Int {
        comment.likeCount
    }
    
    var body: some View {
        VStack {
            if comment.liked {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    singleCommentVM.unlikeComment(
                        appState: appState,
                        globalViewState: viewState,
                        commentId: comment.id,
                        then: { likes in
                            comment.likeCount = likes
                            comment.liked = false
                        }
                    )
                }) {
                    Image(systemName: singleCommentVM.likingComment ? "heart" : "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
                .disabled(singleCommentVM.likingComment)
            } else {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    singleCommentVM.likeComment(
                        appState: appState,
                        globalViewState: viewState,
                        commentId: comment.id,
                        then: { likes in
                            comment.likeCount = likes
                            comment.liked = true
                        }
                    )
                }) {
                    Image(systemName: singleCommentVM.likingComment ? "heart.fill"  : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
                .disabled(singleCommentVM.likingComment)
            }
            
            Text(String(likeCount))
                .font(Font.custom(Poppins.regular, size: 12))
                .opacity(likeCount > 0 ? 1 : 0)
        }
    }
}

struct CommentItem: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    
    @ObservedObject var commentsViewModel: CommentsViewModel
    @StateObject var singleCommentVM = SingleCommentVM()
    @State var comment: Comment
    @State var confirmDelete = false
    @State var relativeTime = ""
    
    let dateTimeFormatter = RelativeDateTimeFormatter()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    func getRelativeTime() -> String {
        if Date().timeIntervalSince(comment.createdAt) < 1 {
            return "just now"
        }
        return dateTimeFormatter.localizedString(for: comment.createdAt, relativeTo: Date())
    }
    
    var canDeleteComment: Bool {
        // True if it is the current user's comment or on the current user's post
        guard case let .user(user) = appState.currentUser else {
            return false
        }
        return comment.user.id == user.id || appState.allPosts.posts[comment.postId]?.user.id == user.id
    }
    
    var isHighlighted: Bool {
        comment.commentId == commentsViewModel.highlightedComment?.commentId
    }
    
    var profileView: some View {
        Profile(
            profileVM: ProfileVM(
                appState: appState,
                globalViewState: viewState,
                user: comment.user
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(backgroundColor))
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                NavTitle("Profile")
            }
        })
    }
    
    var profilePicture: some View {
        URLImage(url: comment.user.profilePictureUrl,
                 loading: Image(systemName: "person.crop.circle").resizable(),
                 failure: Image(systemName: "person.crop.circle").resizable())
            .foregroundColor(.gray)
            .background(Color.white)
            .scaledToFill()
            .frame(width: 36, height: 36)
            .cornerRadius(18)
            .padding(.leading, 5)
            .padding(.top, 10)
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack {
                NavigationLink(destination: profileView) {
                    profilePicture
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading) {
                NavigationLink(destination: profileView) {
                    Text(comment.user.username)
                        .font(Font.custom(Poppins.medium, size: 12))
                        .foregroundColor(.black)
                }
                
                Spacer().frame(height: 3)
                
                Text(comment.content)
                    .font(Font.custom(Poppins.regular, size: 12))
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(relativeTime)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .onReceive(timer, perform: { _ in
                        relativeTime = getRelativeTime()
                    })
                    .onAppear(perform: {
                        relativeTime = getRelativeTime()
                    })
                
                Spacer().frame(height: 2)
            }
            .padding(.vertical, 5)
            
            Spacer()
            
            VStack {
                Spacer().frame(height: 18)
                CommentItemLikeButton(singleCommentVM: singleCommentVM, comment: comment)
            }
        }
        .padding(.leading, 5)
        .padding(.trailing)
        .contentShape(Rectangle())
        .background(canDeleteComment ? Color.gray.opacity(0.15) : Color.clear)
        .background(isHighlighted ? Color.green.opacity(0.15) : Color.clear)
        .contextMenu(canDeleteComment ? ContextMenu(menuItems: {
            Button {
                print("Deleting")
                confirmDelete = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            }) : nil)
        .alert(isPresented: $confirmDelete) {
            Alert(title: Text("Delete comment?"),
                  message: Text("You can't undo this."),
                  primaryButton: .destructive(Text("Delete")) {
                    commentsViewModel.deleteComment(commentId: comment.id)
                  },
                  secondaryButton: .cancel(Text("Cancel")))
        }
    }
}

struct CommentItem_Previews: PreviewProvider {
    static var user = PublicUser(
        username: "gautam",
        firstName: "Gautam",
        lastName: "Mekkat",
        profilePictureUrl: nil,
        postCount: 20,
        followerCount: 20,
        followingCount: 20
    )
    
    static var otherUser = PublicUser(
        username: "someOtherUser",
        firstName: "Gautam",
        lastName: "Mekkat",
        profilePictureUrl: nil,
        postCount: 20,
        followerCount: 20,
        followingCount: 20
    )
    
    static var appState: AppState = {
        let state = AppState(apiClient: APIClient())
        state.currentUser = .user(user)
        return state
    }()
    
    static var commentsViewModel = CommentsViewModel()
    
    static var previews: some View {
        VStack(spacing: 0) {
            CommentItem(commentsViewModel: commentsViewModel, comment: Comment(
                commentId: "commentId",
                user: user,
                postId: "postId",
                content: "I've been here and I love it too! I've been here and I love it too! I've been here and I love it too! I've been here and I love it too! I've been here and I love it too! I've been here and I love it too! I've been here and I love it too! I've been here and I love it too!",
                createdAt: Date(timeIntervalSinceNow: -10),
                likeCount: 10,
                liked: true
            ))
            CommentItem(commentsViewModel: commentsViewModel, comment: Comment(
                commentId: "commentId",
                user: otherUser,
                postId: "postId",
                content: "I've been here and I love it too! This is a medium length comment.",
                createdAt: Date(timeIntervalSinceNow: -10),
                likeCount: 10,
                liked: true
            ))
            CommentItem(commentsViewModel: commentsViewModel, comment: Comment(
                commentId: "commentId",
                user: user,
                postId: "postId",
                content: "short comment",
                createdAt: Date(timeIntervalSinceNow: -10),
                likeCount: 10,
                liked: true
            ))
        }
        .environmentObject(appState)
        .environmentObject(GlobalViewState())
        .previewLayout(PreviewLayout.sizeThatFits)
    }
}
