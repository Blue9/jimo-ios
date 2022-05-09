//
//  EmailLogin.swift
//  Jimo
//
//  Created by Kevin Nizza on 4/28/22.
//

import SwiftUI
import Combine

struct EmailLogin: View {
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel = ViewModel()

    func signIn() {
        hideKeyboard()
        viewModel.signIn(appState: appState)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Image("logo")
                    .aspectRatio(contentMode: .fit)

                Text("Welcome back!")
                TextField("Email", text: $viewModel.email)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("foreground")))

                SecureField("Password", text: $viewModel.password)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("foreground")))

                Button(action: signIn) {
                    Text("Sign in")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(Color("shopping"))
                        .cornerRadius(10)
                }
                .shadow(radius: 5)


            }
            .padding(.horizontal, 24)
        }
        .popup(isPresented: $viewModel.showError, type: .toast, autohideIn: 2) {
            Toast(text: viewModel.error, type: .error)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavTitle("Super secret menu")
            }
        }
    }
}

extension EmailLogin {
    class ViewModel: ObservableObject {
        var cancellable: Cancellable?

        @Published var email = ""
        @Published var password = ""

        @Published var error = ""
        @Published var showError = false

        func setError(_ error: String) {
            showError = true
            self.error = error
        }

        func signIn(appState: AppState) {
            cancellable = appState.signIn(email: email, password: password)
                .sink { completion in
                    if case let .failure(error) = completion {
                        print("Error while signing in", error)
                        self.setError(error.localizedDescription)
                    }
                } receiveValue: { result in

                }
        }
    }
}
