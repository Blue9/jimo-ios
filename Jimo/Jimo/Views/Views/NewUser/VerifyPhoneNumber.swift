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
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Enter your six-digit verification code")

                TextField("Verification code", text: $viewModel.verificationCode)
                    .keyboardType(.numberPad)
                    .frame(height: 40, alignment: .center)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 2)))

                Button(action: {
                    viewModel.verifyPhoneNumber(appState: appState)
                }) {
                    Text("Submit")
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
        .popup(isPresented: $viewModel.showError, type: .toast, autohideIn: 2) {
            Toast(text: viewModel.error, type: .error)
        }
        .trackScreen(.enterVerificationCode)
    }
}

extension VerifyPhoneNumber {
    class ViewModel: ObservableObject {
        @Published var verificationCode = ""
        @Published var error = ""
        @Published var showError = false

        private var cancelBag: Set<AnyCancellable> = .init()

        func setError(_ error: String) {
            self.showError = true
            self.error = error
        }

        func verifyPhoneNumber(appState: AppState) {
            hideKeyboard()
            appState.signInPhone(verificationCode: verificationCode)
                .sink(receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        print("Error", error)
                        self?.setError("Invalid code. Try again.")
                    }
                }, receiveValue: { [weak self] result in
                    self?.verificationCode = ""
                    self?.error = ""
                })
                .store(in: &cancelBag)
        }
    }
}
