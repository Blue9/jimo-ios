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
        Navigator {
            VStack {
                if onboardingModel.onboardingStep == .requestLocation {
                    RequestLocation(onCompleteRequest: onboardingModel.step)
                        .navigationBarHidden(true)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else if onboardingModel.onboardingStep == .followFeatured {
                    FollowFeatured(onboardingModel: onboardingModel)
                        .navigationBarHidden(true)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
            .trackScreen(.onboarding)
        }
    }
}
