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
    
    func setError(_ message: String) {
        self.errorMessage = message
        self.showError = true
    }
}
