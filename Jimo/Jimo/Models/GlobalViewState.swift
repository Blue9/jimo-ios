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
}
