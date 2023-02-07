//
//  GlobalViewState.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/12/21.
//

import Foundation

class GlobalViewState: ObservableObject {
    @Published var showError = false
    @Published var errorMessage = ""

    @Published var showWarning = false
    @Published var warningMessage = ""

    @Published var showSuccess = false
    @Published var successMessage = ""

    @Published var showSignUpPage = false
    @Published var createPostPresented = false

    func setError(_ message: String) {
        self.errorMessage = message
        self.showError = true
    }

    func setWarning(_ message: String) {
        self.warningMessage = message
        self.showWarning = true
    }

    func setSuccess(_ message: String) {
        self.successMessage = message
        self.showSuccess = true
    }

    func showSignUpPage(_ type: SignUpTapSource) {
        Analytics.track(.guestAccountSignUpTap, parameters: ["source": type.analyticsSourceParameter])
        self.showSignUpPage = true
    }
}
