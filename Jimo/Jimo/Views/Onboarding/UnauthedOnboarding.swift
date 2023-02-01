//
//  UnauthedOnboarding.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/1/23.
//

import SwiftUI

struct UnauthedOnboarding: View {
    @StateObject var viewModel = ViewModel()

    var body: some View {
        if !viewModel.onboarded {
            RequestLocation(onCompleteRequest: {
                DispatchQueue.main.async {
                    viewModel.onboarded = true
                }
            })
            .navigationBarHidden(true)
            .trackScreen(.guestLocationOnboarding)
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
