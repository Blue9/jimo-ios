//
//  LoggedInView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/14/21.
//

import SwiftUI

struct LoggedInView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @ObservedObject var onboardingModel: OnboardingModel

    let currentUser: PublicUser

    var body: some View {
        if onboardingModel.isUserOnboarded {
            MainAppView(currentUser: currentUser)
        } else {
            OnboardingView(onboardingModel: appState.onboardingModel)
        }
    }
}
