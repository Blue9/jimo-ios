//
//  CommentItem.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/8/21.
//

import SwiftUI
import Combine

struct CommentItem: View {
    enum Destination: NavigationDestinationEnum {
        case profile(PublicUser)

        func view() -> some View {
            switch self {
            case let .profile(user):
                return ProfileScreen(initialUser: user)
            }
        }
    }
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState

    @ObservedObject var commentsViewModel: ViewPostCommentsViewModel
    @StateObject var viewModel = ViewModel()
    @State private var confirmDelete = false
    @State private var relativeTime = ""
    var navigate: (Destination?) -> Void

    let comment: Comment
    let isMyPost: Bool

    var canDeleteComment: Bool {
        // True if it is the current user's comment or on the current user's post
        guard case let .user(user) = appState.currentUser else {
            return false
        }
        return comment.user.id == user.id || isMyPost
    }

    var isHighlighted: Bool {
        comment.commentId == commentsViewModel.highlightedComment?.commentId
    }

    var profileView: some View {
        ProfileScreen(initialUser: comment.user)
    }

    var profilePicture: some View {
        URLImage(url: comment.user.profilePictureUrl,
                 loading: Image(systemName: "person.crop.circle").resizable())
            .foregroundColor(.gray)
            .background(Color("background"))
            .scaledToFill()
            .frame(width: 36, height: 36)
            .cornerRadius(18)
            .padding(.leading, 5)
            .padding(.top, 10)
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack {
                profilePicture.onTapGesture {
                    self.navigate(.profile(comment.user))
                }

                Spacer()
            }

            VStack(alignment: .leading) {
                Text(comment.user.username.lowercased())
                    .font(.system(size: 12))
                    .bold()
                    .foregroundColor(Color("foreground"))
                    .onTapGesture {
                        self.navigate(.profile(comment.user))
                    }

                Spacer().frame(height: 3)

                Text(comment.content)
                    .font(.system(size: 12))
                    .foregroundColor(Color("foreground"))

                Spacer().frame(height: 2)

                Text(relativeTime)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .onAppear(perform: {
                        if relativeTime == "" {
                            relativeTime = appState.relativeTime(for: comment.createdAt)
                        }
                    })

                Spacer().frame(height: 2)
            }
            .padding(.vertical, 5)

            Spacer()

            VStack {
                Spacer().frame(height: 18)
                CommentItemLikeButton(viewModel: viewModel, comment: comment)
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

private struct CommentItemLikeButton: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState

    @ObservedObject var viewModel: CommentItem.ViewModel

    let comment: Comment

    private var likeCount: Int {
        comment.likeCount
    }

    var body: some View {
        VStack {
            if comment.liked {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.unlikeComment(
                        appState: appState,
                        globalViewState: viewState,
                        commentId: comment.id
                    )
                }) {
                    Image(systemName: viewModel.likingComment ? "heart" : "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
                .disabled(viewModel.likingComment)
            } else {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.likeComment(
                        appState: appState,
                        globalViewState: viewState,
                        commentId: comment.id
                    )
                }) {
                    Image(systemName: viewModel.likingComment ? "heart.fill"  : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
                .disabled(viewModel.likingComment)
            }

            Text(String(likeCount))
                .font(.system(size: 12))
                .foregroundColor(Color("foreground"))
                .opacity(likeCount > 0 ? 1 : 0)
        }
    }
}

extension CommentItem {
    class ViewModel: ObservableObject {
        @Published var likingComment = false
        var cancellable: AnyCancellable?

        func likeComment(
            appState: AppState,
            globalViewState: GlobalViewState,
            commentId: CommentId
        ) {
            likingComment = true
            cancellable = appState.likeComment(commentId: commentId)
                .sink { [weak self] completion in
                    self?.likingComment = false
                    if case .failure = completion {
                        globalViewState.setError("Could not like comment")
                    }
                } receiveValue: { _ in }
        }

        func unlikeComment(
            appState: AppState,
            globalViewState: GlobalViewState,
            commentId: CommentId
        ) {
            likingComment = true
            cancellable = appState.unlikeComment(commentId: commentId)
                .sink { [weak self] completion in
                    self?.likingComment = false
                    if case .failure = completion {
                        globalViewState.setError("Could not unlike comment")
                    }
                } receiveValue: { _ in }
        }
    }

}
