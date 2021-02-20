//
//  OnboardingView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/8/21.
//

import SwiftUI

struct OnboardingView: View {
    var body: some View {
        NavigationView {
            FollowContacts()
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
