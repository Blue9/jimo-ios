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
    
    let waitlistSignUp: Bool
    
    @State private var phoneNumberField = PhoneNumberTextFieldView()
    @State private var error = ""
    @State private var showError = false
    @State private var nextStep: Bool = false
    @State private var getCodeCancellable: Cancellable? = nil
    
    @State private var loading = false
    
    func setError(_ error: String) {
        showError = true
        self.error = error
    }
    
    func getCode() {
        loading = true
        hideKeyboard()
        guard let number = phoneNumberField.getPhoneNumber() else {
            setError("Invalid phone number. Try again.")
            loading = false
            return
        }
        getCodeCancellable = appState.verifyPhoneNumber(phoneNumber: PhoneNumberKit().format(number, toType: .e164))
            .sink(receiveCompletion: { completion in
                loading = false
                if case let .failure(error) = completion {
                    print("Error", error)
                    setError("Invalid phone number. Try again.")
                }
            }, receiveValue: { _ in
                self.error = ""
                self.nextStep = true
            })
    }
    
    var body: some View {
        ZStack {
            VStack {
                Text("Enter your phone #")
                    .font(Font.custom(Poppins.medium, size: 32))
                    .padding(.bottom, 20)
                
                phoneNumberField
                    .frame(height: 40, alignment: .center)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 2)))
                    .padding(.bottom, 20)
                    .onTapGesture {
                        // Don't hide keyboard
                    }
                
                Button(action: getCode) {
                    if loading {
                        Text("Loading...")
                            .font(Font.custom(Poppins.medium, size: 20))
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 60)
                            .foregroundColor(.white)
                            .background(Color.gray)
                            .cornerRadius(10)
                    } else {
                        Text("Next")
                            .font(Font.custom(Poppins.medium, size: 20))
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 60)
                            .foregroundColor(.white)
                            .background(Color("activity"))
                            .cornerRadius(10)
                    }
                }
                .disabled(loading)
                .shadow(radius: 5)
                .padding(.bottom, 10)
                
                Text("By entering your number, you’re agreeing to our Terms of Service and Privacy Policy.")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                NavigationLink(destination: VerifyPhoneNumber(waitlistSignUp: waitlistSignUp), isActive: $nextStep) {
                    EmptyView()
                }
            }
            .padding(.horizontal, 30)
            .frame(maxHeight: .infinity)
            .onTapGesture {
                hideKeyboard()
            }
            .background(Color(.sRGB, red: 0.95, green: 0.95, blue: 0.95, opacity: 1).edgesIgnoringSafeArea(.all))
        }
        .popup(isPresented: $showError, type: .toast, autohideIn: 2) {
            Toast(text: error, type: .error)
        }
    }
}

struct EnterPhoneNumber_Previews: PreviewProvider {
    static var previews: some View {
        EnterPhoneNumber(waitlistSignUp: false)
            .environmentObject(AppState(apiClient: APIClient()))
    }
}
