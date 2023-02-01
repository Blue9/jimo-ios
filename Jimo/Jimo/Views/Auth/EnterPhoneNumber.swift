//
//  EnterPhoneNumber.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/3/21.
//

import SwiftUI
import Combine
import PhoneNumberKit

struct EnterPhoneNumber: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ViewModel()

    var onVerify: () -> Void

    var body: some View {
        ZStack {
            VStack {
                Text("Enter your phone #")
                    .font(.system(size: 32))
                    .padding(.bottom, 20)

                PhoneNumberTextFieldView(phoneNumber: $viewModel.phoneNumber)
                    .frame(height: 40, alignment: .center)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 2)))
                    .padding(.bottom, 20)

                Button(action: {
                    viewModel.getCode(appState: appState)
                }) {
                    if viewModel.loading {
                        ProgressView()
                            .font(.system(size: 20))
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 60)
                            .foregroundColor(.white)
                            .background(Color.gray)
                            .cornerRadius(10)
                    } else {
                        Text("Next")
                            .font(.system(size: 20))
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 60)
                            .foregroundColor(.white)
                            .background(Color(red: 25 / 255, green: 140 / 255, blue: 240 / 255))
                            .cornerRadius(10)
                    }
                }
                .disabled(viewModel.loading)
                .shadow(radius: 5)
                .padding(.bottom, 10)

                VStack {
                    Text("By proceeding, you’re agreeing to our")
                    HStack(spacing: 0) {
                        Link("Terms of Service", destination: URL(string: "https://www.jimoapp.com/terms")!)
                            .foregroundColor(.blue)
                        Text(" and ")
                        Link("Privacy Policy", destination: URL(string: "https://www.jimoapp.com/privacy-policy")!)
                            .foregroundColor(.blue)
                        Text(".")
                    }
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .navDestination(isPresented: $viewModel.nextStep) {
                VerifyPhoneNumber(onVerify: onVerify)
            }
            .navDestination(isPresented: $viewModel.showSecretEmailPage) {
                EmailLogin()
            }
            .padding(.horizontal, 30)
            .frame(maxHeight: .infinity)
            .background(Color("background").edgesIgnoringSafeArea(.all))
            .background(Color.black.opacity(0.05).edgesIgnoringSafeArea(.all))
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(.clear)
        .popup(isPresented: $viewModel.showError, type: .toast, autohideIn: 4) {
            Toast(text: viewModel.error, type: .error)
        }
        .trackScreen(.enterPhoneNumber)
    }
}

extension EnterPhoneNumber {
    class ViewModel: ObservableObject {
        var cancelBag: Set<AnyCancellable> = .init()
        let phoneNumberKit = PhoneNumberKit()

        @Published var phoneNumber: JimoPhoneNumberInput?
        @Published var showError = false
        @Published var nextStep: Bool = false

        @Published private(set) var error = ""
        @Published private(set) var loading = false

        /// Hack to allow logging in with emails
        @Published var showSecretEmailPage = false

        func setError(_ error: String) {
            withAnimation {
                self.error = error
                self.showError = true
            }
        }

        func getCode(appState: AppState) {
            hideKeyboard()

            if case .secretMenu = phoneNumber {
                showSecretEmailPage = true
                return
            }
            guard case let .number(number) = phoneNumber else {
                setError("Invalid phone number.")
                return
            }
            withAnimation {
                loading = true
            }
            appState.verifyPhoneNumber(phoneNumber: phoneNumberKit.format(number, toType: .e164))
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else {
                        return
                    }
                    withAnimation {
                        self.loading = false
                    }
                    if case let .failure(error) = completion {
                        print("Error", error)
                        self.setError(error.localizedDescription)
                    }
                }, receiveValue: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    withAnimation {
                        self.error = ""
                        self.nextStep = true
                    }
                })
                .store(in: &cancelBag)
        }
    }
}
