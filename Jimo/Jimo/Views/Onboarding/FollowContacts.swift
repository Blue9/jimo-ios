//
//  FollowContacts.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/8/21.
//

import SwiftUI

struct FollowContacts: View {
    @EnvironmentObject var appState: AppState

    @ObservedObject var onboardingModel: OnboardingModel
    @StateObject private var contactStore = ExistingContactStore()

    @ViewBuilder var viewBody: some View {
        VStack {
            HStack {
                Spacer()

                Text("Skip")
                    .foregroundColor(.gray)
                    .onTapGesture {
                        onboardingModel.step()
                    }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 30)

            Text("Friends Already Here")
                .font(.system(size: 24))

            Spacer()

            if contactStore.loadingExistingUsers {
                ProgressView()
            } else if let error = contactStore.loadingExistingUsersError {
                if error as? APIError != nil {
                    VStack {
                        Button(action: {
                            contactStore.getExistingUsers(appState: appState)
                        }) {
                            Text("Failed to load friends, tap to try again.")
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 40)
                } else {
                    VStack {
                        Button(action: {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }) {
                            Text("Enable access to your contacts to find friends already on Jimo.")
                                .multilineTextAlignment(.center)
                        }
                        Text("We value and respect your privacy. We do not store your contacts on our servers or share them with anyone else.")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.top, 5)
                            .font(.caption)
                    }
                    .padding(.horizontal, 40)
                }
            } else if contactStore.allUsers.count > 0 {
                UserList(userStore: contactStore)
            } else {
                VStack {
                    Text("No contacts found on Jimo. Tap next to continue.")
                        .foregroundColor(Color("foreground"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 15)

                    Button(action: {
                        onboardingModel.step()
                    }) {
                        LargeButton("Next")
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .padding(.bottom, 100)
        .onAppear {
            contactStore.getExistingUsers(appState: appState)
        }
        .foregroundColor(Color("foreground"))
        .background(Color("background").edgesIgnoringSafeArea(.all))
    }

    var body: some View {
        ZStack {
            viewBody
        }
        .popup(isPresented: $contactStore.followManyFailed, type: .toast, autohideIn: 2) {
            Toast(text: "Failed to follow contacts", type: .error)
        }
    }
}
