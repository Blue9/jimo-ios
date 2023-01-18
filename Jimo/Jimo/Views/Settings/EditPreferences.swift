//
//  EditPreferences.swift
//  Jimo
//
//  Created by Gautam Mekkat on 6/4/21.
//

import SwiftUI

struct EditPreferences: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState

    @ObservedObject var settingsViewModel: SettingsViewModel
    @State private var showSubmitFeedback = false
    @State private var showConfirmDelete = false

    var notificationSection: some View {
        Group {
            Toggle(isOn: $settingsViewModel.followNotifications) {
                VStack(alignment: .leading) {
                    Text("Followers")

                    Text("Get notified when someone follows you")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            Toggle(isOn: $settingsViewModel.postNotifications) {
                VStack(alignment: .leading) {
                    Text("Posts")

                    Text("Get notified when someone you follow makes a new post")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            Toggle(isOn: $settingsViewModel.postLikedNotifications) {
                VStack(alignment: .leading) {
                    Text("Post likes and saves")

                    Text("Get notified when someone likes or saves your post")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            Toggle(isOn: $settingsViewModel.commentNotifications) {
                VStack(alignment: .leading) {
                    Text("Comments")

                    Text("Get notified when someone comments on your post or replies to your comment")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            Toggle(isOn: $settingsViewModel.commentLikedNotifications) {
                VStack(alignment: .leading) {
                    Text("Comment likes")

                    Text("Get notified when someone likes your comment")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
        }
    }

    var body: some View {
        Form {
            Section(header: Text("Notifications")) {
                notificationSection
                savePreferencesButton("notification")
            }

            Section(header: Text("Privacy")) {
                Toggle(isOn: $settingsViewModel.searchableByPhoneNumber) {
                    VStack(alignment: .leading) {
                        Text("Searchable by phone number")

                        Text("Allow other users to find you using your phone number")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                savePreferencesButton("privacy")
            }

            Section(header: Text("Danger Zone")) {
                if #available(iOS 15.0, *) {
                    Button { showConfirmDelete = true } label: {
                        Text("Delete account")
                            .foregroundColor(.red)
                    }
                    .alert("Are you sure?", isPresented: $showConfirmDelete) {
                        Button("Delete account", role: .destructive, action: {
                            settingsViewModel.deleteAccount(
                                appState: appState,
                                viewState: globalViewState
                            )
                        })

                        Button("Submit feedback", action: {
                            showConfirmDelete = false
                            showSubmitFeedback = true
                        })

                        Button("Cancel", role: .cancel, action: {
                            showConfirmDelete = false
                        }).keyboardShortcut(.defaultAction)
                    } message: {
                        Text("Your account will be immediately deactivated, "
                             + "and all your personal data, including images and posts, "
                             + "will be permanently deleted within the next 24 hours.")
                    }
                } else {
                    Button {
                        showConfirmDelete = true
                    } label: {
                        Text("Delete account")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showConfirmDelete) {
                        Alert(
                            title: Text("Are you sure?"),
                            message: Text(
                                "Your account will be immediately deactivated, "
                                + "and all your personal data, including images and posts, "
                                + "will be permanently deleted within the next 24 hours."
                            ),
                            primaryButton: .destructive(
                                Text("Delete account"),
                                action: {
                                    settingsViewModel.deleteAccount(
                                        appState: appState,
                                        viewState: globalViewState
                                    )
                                }
                            ),
                            secondaryButton: .cancel())
                    }
                }
            }
        }
        .background(NavigationLink(destination: LazyView { Feedback() }, isActive: $showSubmitFeedback, label: {}))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(Color("background")))
        .navigationTitle(Text("Preferences"))
    }

    @ViewBuilder
    private func savePreferencesButton(_ type: String) -> some View {
        Button {
            settingsViewModel.updatePreferences(appState: appState, viewState: globalViewState)
        } label: {
            Text("Save \(type) preferences").foregroundColor(.blue)
        }
    }
}
