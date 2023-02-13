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

    @State var city: String?
    @State var showSubmitPlacesWarning = false

    var body: some View {
        Navigator {
            VStack {
                switch onboardingModel.onboardingStep {
                case .requestLocation:
                    RequestLocation(onCompleteRequest: onboardingModel.step)
                case .cityOnboarding:
                    CityOnboarding(selectCity: { city in
                        DispatchQueue.main.async {
                            self.city = city
                        }
                    })
                case .completed:
                    EmptyView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .navigation(destination: $city) {
                city != nil ? CityPlaces(city: city!, done: onboardingModel.step) : nil
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            .trackScreen(.onboarding)
        }
    }
}
