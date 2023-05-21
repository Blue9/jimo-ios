//
//  OnboardingView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/8/21.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var onboardingModel: OnboardingModel
    @StateObject var navigationState = NavigationState()

    @State var city: String?
    @State var showSubmitPlacesWarning = false

    var body: some View {
        Navigator(state: navigationState) {
            VStack {
                switch onboardingModel.onboardingStep {
                case .requestLocation:
                    RequestLocation(onCompleteRequest: onboardingModel.step)
                case .followFeatured:
                    FollowFeatured(onboardingModel: onboardingModel)
                case .cityOnboarding:
                    CityOnboarding(selectCity: { city in
                        Analytics.track(.onboardingCitySelected, parameters: ["city": city.name])
                        DispatchQueue.main.async {
                            if city == .other {
                                onboardingModel.step()
                            } else {
                                navigationState.push(.cityOnboarding(city: city.name))
                            }
                        }
                    })
                case .completed:
                    EmptyView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            .trackScreen(.onboarding)
        }
        .environmentObject(onboardingModel)
    }
}
