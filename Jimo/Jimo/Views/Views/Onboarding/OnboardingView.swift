//
//  OnboardingView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/8/21.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var onboardingModel: OnboardingModel
    
    var body: some View {
        NavigationView {
            VStack {
                if onboardingModel.onboardingStep == .requestLocation {
                    RequestLocation(onCompleteRequest: onboardingModel.step)
                        .navigationBarHidden(true)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else if onboardingModel.onboardingStep == .requestContacts {
                    RequestPermission(
                        onCompleteRequest: onboardingModel.step,
                        action: {
                            PermissionManager.shared.requestContacts {_, _ in }
                        },
                        title: "Allowing contacts helps you find friends already on Jimo",
                        imageName: "contacts-icon",
                        caption: "e.g., Your friend Alex is on Jimo!"
                    )
                    .navigationBarHidden(true)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else if onboardingModel.onboardingStep == .followContacts {
                    FollowContacts(onboardingModel: onboardingModel)
                        .navigationBarHidden(true)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else if onboardingModel.onboardingStep == .followFeatured {
                    FollowFeatured(onboardingModel: onboardingModel)
                        .navigationBarHidden(true)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else if onboardingModel.onboardingStep == .requestNotifications {
                    RequestPermission(
                        onCompleteRequest: onboardingModel.step,
                        action: PermissionManager.shared.requestNotifications,
                        title: "Enable notifications to know when your friends interact with your recs",
                        imageName: "notifications-icon",
                        caption: "e.g., Alex likes your post"
                    )
                    .navigationBarHidden(true)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
