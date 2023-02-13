//
//  NotificationSettings.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/8/23.
//

import SwiftUI

struct NotificationSettings: View {
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @ObservedObject var settingsViewModel: SettingsViewModel
    @State private var shouldRequestNotifications = false

    var body: some View {
        Group {
            if shouldRequestNotifications {
                Button {
                    PermissionManager.shared.requestNotifications()
                } label: {
                    Text("Allow notification permissions to edit").foregroundColor(.blue)
                }
            }
            mainBody.disabled(shouldRequestNotifications)
            Button {
                settingsViewModel.updatePreferences(appState: appState, viewState: viewState)
            } label: {
                Text("Save notification preferences").foregroundColor(shouldRequestNotifications ? .gray : .blue)
            }.disabled(shouldRequestNotifications)
        }
        .onAppear {
            PermissionManager.shared.getNotificationAuthStatus { status in
                DispatchQueue.main.async {
                    shouldRequestNotifications = status != .authorized
                }
            }
        }
        .onChange(of: scenePhase) { _ in
            PermissionManager.shared.getNotificationAuthStatus { status in
                DispatchQueue.main.async {
                    shouldRequestNotifications = status != .authorized
                }
            }
        }
    }

    @ViewBuilder
    var mainBody: some View {
        Group {
            Toggle(isOn: shouldRequestNotifications ? .constant(false) : $settingsViewModel.followNotifications) {
                VStack(alignment: .leading) {
                    Text("Followers")

                    Text("Get notified when someone follows you")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            Toggle(isOn: shouldRequestNotifications ? .constant(false) : $settingsViewModel.postNotifications) {
                VStack(alignment: .leading) {
                    Text("Posts")

                    Text("Get notified when someone you follow makes a new post")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            Toggle(isOn: shouldRequestNotifications ? .constant(false) : $settingsViewModel.postLikedNotifications) {
                VStack(alignment: .leading) {
                    Text("Post likes")

                    Text("Get notified when someone likes your post")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            Toggle(isOn: shouldRequestNotifications ? .constant(false) : $settingsViewModel.commentNotifications) {
                VStack(alignment: .leading) {
                    Text("Comments")

                    Text("Get notified when someone comments on your post or replies to your comment")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            Toggle(isOn: shouldRequestNotifications ? .constant(false) : $settingsViewModel.commentLikedNotifications) {
                VStack(alignment: .leading) {
                    Text("Comment likes")

                    Text("Get notified when someone likes your comment")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
        }
    }
}
