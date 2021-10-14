//
//  VerifyPhoneNumber.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/3/21.
//

import SwiftUI
import Combine

struct VerifyPhoneNumber: View {
    @EnvironmentObject var appState: AppState
        
    @State private var verificationCode = ""
    @State private var error = ""
    @State private var showError = false
    @State private var verifyCancellable: Cancellable? = nil
    
    func setError(_ error: String) {
        showError = true
        self.error = error
    }
    
    func verifyPhoneNumber() {
        hideKeyboard()
        verifyCancellable = appState.signInPhone(verificationCode: verificationCode)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error", error)
                    setError("Invalid code. Try again.")
                }
            }, receiveValue: { result in
                self.verificationCode = ""
                self.error = ""
            })
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Enter your six-digit verification code")
                
                TextField("Verification code", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .frame(height: 40, alignment: .center)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 2)))
                
                Button(action: verifyPhoneNumber) {
                    Text("Sign in")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 60)
                        .foregroundColor(.white)
                        .background(Color(red: 25 / 255, green: 140 / 255, blue: 240 / 255))
                        .cornerRadius(10)
                }
                .shadow(radius: 5)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(.clear)
        .popup(isPresented: $showError, type: .toast, autohideIn: 2) {
            Toast(text: error, type: .error)
        }
    }
}


struct VerifyPhoneNumber_Previews: PreviewProvider {
    static var previews: some View {
        VerifyPhoneNumber()
            .environmentObject(AppState(apiClient: APIClient()))
            .environmentObject(GlobalViewState())
    }
}
