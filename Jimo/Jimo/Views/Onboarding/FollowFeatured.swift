//
//  FollowFeatured.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/14/21.
//

import SwiftUI
import PopupView

struct FollowFeatured: View {
    @EnvironmentObject var appState: AppState

    @ObservedObject var onboardingModel: OnboardingModel
    @StateObject private var featuredUserStore = FeaturedUserStore()

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

            Text("Featured Jimo Users")
                .font(.system(size: 24))

            Spacer()

            if featuredUserStore.loadingSuggestedUsers {
                ProgressView()
            } else if featuredUserStore.loadingSuggestedUsersError != nil {
                VStack {
                    Button(action: {
                        featuredUserStore.getExistingUsers(appState: appState)
                    }) {
                        Text("Failed to load featured users, tap to try again.")
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 40)
            } else {
                UserList(userStore: featuredUserStore)
            }

            Spacer()
        }
        .padding(.bottom, 100)
        .onAppear {
            featuredUserStore.getExistingUsers(appState: appState)
        }
        .background(Color("background").edgesIgnoringSafeArea(.all))
    }

    var body: some View {
        VStack {
            ZStack {
                viewBody
            }
            .popup(isPresented: $featuredUserStore.followManyFailed) {
                Toast(text: "Failed to follow users", type: .error)
            } customize: {
                $0.type(.toast).autohideIn(2)
            }
        }
    }
}
