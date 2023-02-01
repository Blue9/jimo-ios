//
//  UnauthedOnboarding.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/1/23.
//

import SwiftUI

struct UnauthedOnboarding: View {
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel = ViewModel()

    var body: some View {
        if !viewModel.onboarded {
            VStack {
                HStack {
                    Button {
                        appState.signOut()
                    } label: {
                        Text("Back")
                    }
                    Spacer()
                }.padding()

                RequestLocation(onCompleteRequest: {
                    DispatchQueue.main.async {
                        appState.onboardingModel.skipLocationIfGranted()
                        viewModel.onboarded = true
                    }
                })
                .trackScreen(.guestLocationOnboarding)
            }
        } else {
            MainAppView(currentUser: nil)
        }
    }
}

extension UnauthedOnboarding {
    class ViewModel: ObservableObject {
        @Published var onboarded: Bool

        init() {
            self.onboarded = PermissionManager.shared.locationManager.location != nil
        }
    }
}
