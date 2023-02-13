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

    var body: some View {
        Form {
            Section(header: Text("Notifications")) {
                NotificationSettings(settingsViewModel: settingsViewModel)
            }

            Section(header: Text("Privacy")) {
                Toggle(isOn: $settingsViewModel.searchableByPhoneNumber) {
                    VStack(alignment: .leading) {
                        Text("Discoverable by contacts")

                        Text("Allow friends who have you in their contacts to add you")
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
        .navDestination(isPresented: $showSubmitFeedback) {
            Feedback()
        }
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
