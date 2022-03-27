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
            if !onboardingModel.completedContactsOnboarding {
                FollowContacts(onboardingModel: onboardingModel)
                    .navigationBarHidden(true)
            } else if !onboardingModel.completedFeaturedUsersOnboarding {
                FollowFeatured(onboardingModel: onboardingModel)
                    .navigationBarHidden(true)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
