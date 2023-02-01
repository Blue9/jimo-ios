//
//  UnauthedMapUserFilter.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/31/23.
//

import SwiftUI
import FirebaseRemoteConfig

private struct SignUpAlert: Equatable {
    var isPresented: Bool
    var text: String
    var event: AnalyticsName
}

private struct AllowedUser: Codable, Hashable {
    var userId: UserId
    var profilePictureUrl: String?
    var username: String
}

struct UnauthedMapUserFilter: View {
    @Namespace private var userFilter
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @StateObject private var viewModel = ViewModel()

    @State private var showCustomUsersSheet = false
    @Binding var customUserFilter: Set<UserId>

    @State private var alert: SignUpAlert = .init(
        isPresented: false,
        text: "Sign up to view community posts.",
        event: .allFilterSignUpTap
    )

    private func showAlert(_ text: String, event: AnalyticsName) {
        self.alert = .init(isPresented: true, text: text, event: event)
    }

    var body: some View {
        HStack(spacing: 0) {
            view(for: .saved)
                .onTapGesture { self.showAlert("Sign up to start saving places.", event: .saveFilterSignUpTap) }
            view(for: .me)
                .onTapGesture { self.showAlert("Sign up to start posting places.", event: .meFilterSignUpTap)}
            view(for: .following)
                .onTapGesture { self.showAlert("Sign up to start following others.", event: .followingFilterSignUpTap) }
            view(for: .community)
                .onTapGesture { self.showAlert("Sign up to view community posts.", event: .allFilterSignUpTap) }
            view(for: .custom)
                .background(Color("foreground").opacity(0.1))
                .onTapGesture {
                    self.showCustomUsersSheet = true
                }
                .cornerRadius(10)
        }.sheet(isPresented: $showCustomUsersSheet) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    Text("Featured Profiles")
                        .bold()
                        .padding(.vertical, 10)
                    Text("Sign up to view recs from the rest of the community.").font(.caption)
                    ForEach(viewModel.allowedUsers, id: \.userId) { user in
                        SelectableUser(customUserFilter: $customUserFilter, user: user)
                            .matchedGeometryEffect(id: user.userId, in: userFilter)
                    }
                    .animation(.easeInOut, value: userFilter)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .font(.system(size: 15))
            }
        }
        .padding(5)
        .background(Color("foreground").opacity(0.1))
        .cornerRadius(10)
        .alert("Account required", isPresented: $alert.isPresented) {
            Button("Later", action: {
                alert.isPresented = false
            })

            Button("Sign up", action: {
                Analytics.track(alert.event)
                viewState.showSignUpPage = true
            })
        } message: {
            Text(alert.text)
        }
        .onAppear {
            if viewModel.showError {
                viewModel.showError = false
                viewState.setError("Could not parse list of users. Try again later.")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.attemptReload()
        }
    }

    @ViewBuilder func view(for mapType: MapType) -> some View {
        VStack {
            if let systemName = mapType.systemImage {
                Image(systemName: systemName)
                    .resizable()
                    .font(.system(size: 14, weight: .thin))
                    .foregroundStyle(Color("foreground").opacity(0.8), Color("foreground").opacity(0.1))
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if mapType == .community {
                GlobalViewFilterButton()
            } else if mapType == .me {
                Image(systemName: "person.crop.circle.fill")
                    .renderingMode(.original)
                    .resizable()
                    .font(.system(size: 14, weight: .thin))
                    .foregroundColor(Color("background").opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(100)
            }
            Text(mapType.buttonName)
                .lineLimit(1)
                .font(.caption)
        }
        .padding(5)
        .contentShape(Rectangle())
        .cornerRadius(10)
    }

    fileprivate class ViewModel: ObservableObject {
        @Published var allowedUsers: [AllowedUser] = []
        @Published var showError: Bool = false

        init() {
            self.attemptReload(showErrorOnFailure: true)
        }

        func attemptReload(showErrorOnFailure: Bool = false) {
            if let value = RemoteConfig.remoteConfig().configValue(forKey: "featuredUsersForGuestMap").jsonValue,
               let parsed = value as? [[String: String]] {
                self.allowedUsers = parsed.compactMap { item in
                    guard let userId = item["userId"], let username = item["username"] else {
                        return nil
                    }
                    return AllowedUser(
                        userId: userId,
                        profilePictureUrl: item["profilePictureUrl"],
                        username: username
                    )
                }
            } else {
                self.showError = showErrorOnFailure
            }
        }
    }
}

private struct SelectableUser: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState

    @Binding var customUserFilter: Set<UserId>

    var user: AllowedUser

    @ViewBuilder var profilePicture: some View {
        ZStack {
            URLImage(
                url: user.profilePictureUrl,
                loading: Image(systemName: "person.crop.circle"),
                thumbnail: true
            )
            .foregroundColor(.gray)
            .frame(width: 40, height: 40)
            .cornerRadius(20)
        }
    }

    var body: some View {
        HStack {
            profilePicture
            VStack(alignment: .leading) {
                Text(user.username.lowercased())
                    .font(.system(size: 15))
                    .bold()
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            Spacer()
            CircularCheckbox(selected: customUserFilter.contains(user.userId))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if customUserFilter.contains(user.userId) {
                customUserFilter.remove(user.userId)
            } else {
                customUserFilter.insert(user.userId)
            }
        }
    }
}
