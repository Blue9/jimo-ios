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
    
    var profileVM: ProfileVM
    var mapVM: MapViewModel
    
    var body: some View {
        if onboardingModel.isUserOnboarded {
            MainAppView(profileVM: profileVM, mapVM: mapVM)
        } else {
            OnboardingView(onboardingModel: appState.onboardingModel)
        }
    }
}
