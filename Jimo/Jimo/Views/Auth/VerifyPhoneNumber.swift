//
//  VerifyPhoneNumber.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/3/21.
//

import SwiftUI
import PopupView
import Combine

struct VerifyPhoneNumber: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ViewModel()
    @FocusState private var isFocused: Bool
    @State private var showHelpText = false
    @State private var showHelpSheet = false

    var onVerify: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Enter your six-digit verification code")

                TextField("Verification code", text: $viewModel.verificationCode)
                    .focused($isFocused)
                    .keyboardType(.numberPad)
                    .frame(height: 40, alignment: .center)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 2))
                    )
                    .appear {
                        isFocused = true
                    }

                Button(action: {
                    viewModel.verifyPhoneNumber(appState: appState, onVerify: onVerify)
                }) {
                    Text("Submit")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 60)
                        .foregroundColor(.white)
                        .background(Color(red: 25 / 255, green: 140 / 255, blue: 240 / 255))
                        .cornerRadius(10)
                }
                .shadow(radius: 5)

                Button {
                    showHelpSheet = true
                } label: {
                    Text("Not receiving a code?")
                        .foregroundColor(.blue)
                        .padding()
                        .contentShape(Rectangle())
                }.opacity(showHelpText ? 1.0 : 0.0)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.showHelpText = true
            }
        }
        .sheet(isPresented: $showHelpSheet) {
            TroubleshootingView()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(.clear)
        .popup(isPresented: $viewModel.showError) {
            Toast(text: viewModel.error, type: .error)
        } customize: {
            $0.type(.toast).autohideIn(2)
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

        func verifyPhoneNumber(appState: AppState, onVerify: @escaping () -> Void) {
            hideKeyboard()
            appState.signInPhone(verificationCode: verificationCode)
                .sink(receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        print("Error", error)
                        self?.setError("Error: \(error.localizedDescription)")
                    }
                }, receiveValue: { [weak self] _ in
                    self?.verificationCode = ""
                    self?.error = ""
                    onVerify()
                })
                .store(in: &cancelBag)
        }
    }
}

private struct TroubleshootingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Spacer()
                Text("Troubleshooting")
                    .bold()
                    .padding(.bottom)
                Spacer()
            }

            Text("If you don't receive a verification code after a few minutes, please try the following.")
            Text("Ensure your phone number is entered correctly, including the country code.")

            HStack {
                Text("Examples:").bold()
                Spacer()
            }
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("+1 (845) 462-5555")
                    Spacer()
                }

                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("462-5555")
                    Spacer()
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("+44 333 772 0020")
                    Spacer()
                }

                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("333 772 0020")
                    Spacer()
                }
            }.padding(.leading, 5)

            Text("If you are still not receiving a verification code, make sure the number you have entered is activated and can receive SMS messages.")

            Text("Please reach out to support@jimoapp.com if the issue persists.")

            Spacer()
        }.padding(20)
    }
}
