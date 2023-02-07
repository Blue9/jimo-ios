//
//  PlaceDetailsView.swift
//  Jimo
//
//  Created by admin on 12/23/22.
//

import Combine
import MapKit
import SwiftUI
import SwiftUIPager

struct PlaceDetailsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState

    @ObservedObject var viewModel: PlaceDetailsViewModel

    @State private var initialized = false

    // Guest accounts
    @State private var signUpAlert = SignUpAlert(isPresented: false, source: .none)

    fileprivate func showSignUpAlert(_ source: SignUpTapSource) {
        self.signUpAlert = .init(isPresented: true, source: source)
    }

    var body: some View {
        BasePlaceDetailsView(viewModel: viewModel, showSignUpAlert: showSignUpAlert)
            .onAppear {
                DispatchQueue.main.async {
                    if !initialized {
                        initialized = true
                        viewModel.initialize(appState: appState, viewState: viewState)
                    }
                }
            }
            .alert("Account required", isPresented: $signUpAlert.isPresented) {
                Button("Later", action: {
                    signUpAlert = .init(isPresented: false, source: .none)
                })

                Button("Sign up", action: {
                    viewState.showSignUpPage(signUpAlert.source)
                })
            } message: {
                Text(signUpAlert.source.signUpNudgeText ?? "Sign up for the full experience.")
            }
    }
}

private struct BasePlaceDetailsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @ObservedObject var viewModel: PlaceDetailsViewModel

    var showSignUpAlert: (SignUpTapSource) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            HStack(spacing: 10) {
                CreatePostButton(viewModel: viewModel)
                    .modify {
                        if appState.currentUser.isAnonymous {
                            $0.disabled(true).onTapGesture { showSignUpAlert(.placeDetailsPost) }
                        }
                    }

                SavePlaceButton(viewModel: viewModel)
                    .modify {
                        if appState.currentUser.isAnonymous {
                            $0.disabled(true).onTapGesture { showSignUpAlert(.placeDetailsSave) }
                        }
                    }
            }.padding(.horizontal, 10)

            HStack {
                if let phoneNumber = viewModel.phoneNumber {
                    PhoneNumberButton(phoneNumber: phoneNumber)
                }
                if let url = viewModel.website {
                    WebsiteButton(url: url)
                }
                OpenInMapsButton(viewModel: viewModel)

                Spacer()
            }
            .padding(.horizontal, 10)
            .foregroundColor(.white)
            .padding(.bottom, 10)

            VStack(alignment: .leading) {
                if let save = viewModel.details?.mySave {
                    VStack(alignment: .leading, spacing: 10) {
                        Divider()
                        HStack {
                            Text("Saved \(appState.relativeTime(for: save.createdAt)) - ")
                                .italic()
                            +
                            Text(save.note.isEmpty ? "No note" : save.note)
                        }.font(.caption)
                        Divider()
                    }
                }

                if appState.currentUser.isAnonymous {
                    Button {
                        viewState.showSignUpPage(.placeDetailsNudge)
                    } label: {
                        Text("Sign up to post and save places.")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    Divider()
                }

                if let post = viewModel.details?.myPost {
                    HStack {
                        Text("Me")
                            .font(.system(size: 15))
                            .bold()
                        Spacer()
                    }
                    MaybeGuestPostPage(
                        // Don't update model store if we're using cached post
                        // data because newer data may already be in the store
                        postVM: ModelProvider.getPostModel(for: post),
                        showSignUpAlert: showSignUpAlert
                    )
                }

                if viewModel.followingPosts.count > 0 {
                    PostCarousel(
                        placeDetailsViewModel: viewModel,
                        text: "Friends' Posts (\(viewModel.followingPosts.count))",
                        posts: viewModel.followingPosts,
                        showSignUpAlert: showSignUpAlert
                    )
                }

                if viewModel.featuredPosts.count > 0 {
                    PostCarousel(
                        placeDetailsViewModel: viewModel,
                        text: "Featured (\(viewModel.featuredPosts.count))",
                        posts: viewModel.featuredPosts,
                        showSignUpAlert: showSignUpAlert
                    )
                }

                if appState.currentUser.isAnonymous {
                    HStack {
                        Text("Community")
                            .font(.system(size: 15))
                            .bold()
                        Spacer()
                    }
                    PostPagePlaceholder()
                        .redacted(reason: .placeholder)
                        .overlay(Color("background").opacity(0.3))
                        .overlay(
                            Button {
                                viewState.showSignUpPage(.placeDetailsCommunityNudge)
                            } label: {
                                Text("Sign up to view community recs")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        )
                } else if viewModel.communityPosts.count > 0 {
                    PostCarousel(
                        placeDetailsViewModel: viewModel,
                        text: "Community (\(viewModel.communityPosts.count))",
                        posts: viewModel.communityPosts,
                        showSignUpAlert: showSignUpAlert
                    )
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)

            Spacer()
        }
        .padding(.bottom, 49)
    }
}

private struct CreatePostButton: View {
    @ObservedObject var viewModel: PlaceDetailsViewModel
    var body: some View {
        Button {
            DispatchQueue.main.async {
                Analytics.track(.mapCreatePostTapped)
                viewModel.showCreateOrEditPostSheet()
            }
        } label: {
            HStack {
                Spacer()
                Text(viewModel.isPosted ? "Update" : "Post")
                    .font(.system(size: 15))
                    .fontWeight(.medium)
                Image(systemName: "plus.app")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                Spacer()
            }
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(.blue)
            .cornerRadius(5)
        }
        .sheet(isPresented: $viewModel.showCreatePost) {
            CreatePostWithModel(
                createPostVM: viewModel.createPostVM,
                presented: $viewModel.showCreatePost
            )
        }
    }
}

private struct SavePlaceButton: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @ObservedObject var viewModel: PlaceDetailsViewModel

    @State private var showSaveNoteAlert = false

    var body: some View {
        Button {
            DispatchQueue.main.async {
                if viewModel.isSaved {
                    viewModel.unsavePlace(appState: appState, viewState: viewState)
                } else {
                    showSaveNoteAlert = true
                }
            }
        } label: {
            HStack {
                Spacer()
                Text(viewModel.isSaved ? "Saved" : "Save")
                    .font(.system(size: 15))
                    .fontWeight(.medium)
                Image(systemName: viewModel.isSaved ? "bookmark.fill" : "bookmark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                Spacer()
            }
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(.orange)
            .cornerRadius(5)
        }
        .textAlert(
            isPresented: $showSaveNoteAlert,
            title: "Save \(viewModel.name)",
            message: "Add a note (Optional)",
            submitText: "Save",
            action: { note in
                Analytics.track(.mapSavePlace)
                viewModel.savePlace(note: note, appState: appState, viewState: viewState)
            }
        )
    }
}

private struct PhoneNumberButton: View {
    var phoneNumber: String

    var body: some View {
        Button {
            if let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                UIApplication.shared.open(url)
            }
        } label: {
            VStack {
                Image(systemName: "phone.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                Text("Call")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 70, height: 75)
            .foregroundColor(.blue)
            .background(Color("foreground").opacity(0.1))
            .cornerRadius(5)
        }
    }
}

private struct WebsiteButton: View {
    var url: URL

    var body: some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            VStack {
                Image(systemName: "globe")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                Text("Website")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 70, height: 75)
            .foregroundColor(.blue)
            .background(Color("foreground").opacity(0.1))
            .cornerRadius(5)
        }
    }
}

private struct OpenInMapsButton: View {
    @ObservedObject var viewModel: PlaceDetailsViewModel

    var body: some View {
        Button {
            viewModel.openInMaps()
        } label: {
            VStack {
                Image(systemName: "arrow.up.right.square")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                Text("Maps")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 70, height: 75)
            .foregroundColor(.blue)
            .background(Color("foreground").opacity(0.1))
            .cornerRadius(5)
        }
    }
}

private struct PostCarousel: View {
    @ObservedObject var placeDetailsViewModel: PlaceDetailsViewModel
    @StateObject var page: Page = .first()

    var text: String
    var posts: [Post]
    var showSignUpAlert: (SignUpTapSource) -> Void

    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 15))
                .bold()
            Spacer()
        }

        Pager(page: page, data: posts) { post in
            MaybeGuestPostPage(
                // Don't update model store if we're using cached post
                // data because newer data may already be in the store
                postVM: ModelProvider.getPostModel(for: post),
                showSignUpAlert: showSignUpAlert
            )
        }
        .padding(10)
        .alignment(.start)
        .sensitivity(.custom(0.10))
        .pagingPriority(.high)
        .frame(height: 120)
    }
}
