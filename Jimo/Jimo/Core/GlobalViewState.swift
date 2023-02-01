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

    @Published var shareAction: ShareAction? {
        didSet {
            if shareAction != nil {
                DispatchQueue.main.async {
                    self.showShareOverlay = true
                }
            }
        }
    }
    @Published var showShareOverlay = false {
        didSet {
            if !showShareOverlay {
                DispatchQueue.main.async {
                    self.shareAction = nil
                }
            }
        }
    }

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

    func showShareOverlay(for shareAction: ShareAction) {
        self.shareAction = shareAction
    }
}
