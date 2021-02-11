//
//  CreateProfileView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/12/20.
//

import SwiftUI
import Combine

let usernameRegex = #"[a-zA-Z0-9_]+"#;

struct Field: View {
    @Binding var value: String
    
    let placeholder: String
    let errorMessage: String
    let isValid: (String) -> Bool
    
    var inputFilter: ((String) -> String)? = nil
    var autocapitalization: UITextAutocapitalizationType = .words
    
    var valid: Bool {
        isValid(value)
    }
    
    var body: some View {
        let field = TextField(placeholder, text: $value)
            .autocapitalization(autocapitalization)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10)
                            .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 2)))
        
        if let filter = inputFilter {
            field.onReceive(Just(value), perform: { newValue in
                let filtered = filter(newValue)
                if filtered != newValue {
                    self.value = filtered
                }
            })
        } else {
            field
        }
        
        Text(errorMessage)
            .foregroundColor(valid ? .green : .gray)
            .padding(.bottom, 10)
    }
}

struct CreateProfileBody: View {
    @EnvironmentObject var appState: AppState
    
    static let usernameReq = "Usernames should be 3-20 characters"
    static let nameReq = "Required field"
    static let serverError = "Unknown server error, try again later"
    
    @State private var cancellable: Cancellable? = nil
    
    @State private var requestError = ""

    @State private var username: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var privateAccount = false
    
    @State private var showServerError = false
    @State private var showRequestError = false
    
    func validUsername(username: String) -> Bool {
        return username.count >= 3 && username.count <= 20
    }
    
    func validName(name: String) -> Bool {
        return name.count > 0 && name.count < 120
    }
    
    var allValid: Bool {
        validUsername(username: username) &&
            validName(name: firstName) &&
            validName(name: lastName)
    }
    
    func createProfile() {
        hideKeyboard()
        let request = CreateUserRequest(
            username: username,
            firstName: firstName,
            lastName: lastName)
        cancellable = appState.createUser(request)
            .sink(receiveCompletion: { completion in
                if case .failure(_) = completion {
                    showServerError = true
                }
            }, receiveValue: { response in
                if let error = response.error {
                    if let uidError = error.uid {
                        requestError = uidError
                    } else if let usernameError = error.username {
                        requestError = usernameError
                    } else if let firstNameError = error.firstName {
                        requestError = firstNameError
                    } else if let lastNameError = error.lastName {
                        requestError = lastNameError
                    } else {
                        requestError = "Unknown error"
                    }
                    showRequestError = true
                }
            })
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                Image("logo")
                    .aspectRatio(contentMode: .fit)

                Text("Almost there!")
                    .padding(.bottom)
                
                Field(value: $username, placeholder: "Username",
                      errorMessage: CreateProfileBody.usernameReq,
                      isValid: self.validUsername,
                      inputFilter: { username in
                        if let range = username.range(
                            of: usernameRegex,
                            options: .regularExpression) {
                            return String(username[range])
                        }
                        return ""
                      },
                      autocapitalization: .none)
                
                Field(value: $firstName, placeholder: "First name",
                      errorMessage: CreateProfileBody.nameReq,
                      isValid: self.validName)
                
                Field(value: $lastName, placeholder: "Last name",
                      errorMessage: CreateProfileBody.nameReq,
                      isValid: self.validName)
                
                // Toggle(isOn: $privateAccount) {
                //     Text("Private account")
                // }
                
                Button(action: createProfile) {
                    Text("Create profile")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(Color("attraction"))
                        .cornerRadius(10)
                }
                .disabled(!allValid)
                .padding(.vertical, 20)
                .shadow(radius: 5)
            }
            .padding(.horizontal, 24)
        }
        .popup(isPresented: $showServerError, type: .toast, position: .bottom, autohideIn: 2) {
            Toast(text: "Unknown server error. Try again later.", type: .error)
        }
        .popup(isPresented: $showRequestError, type: .toast, position: .bottom, autohideIn: 2) {
            Toast(text: requestError, type: .warning)
        }
        //.navigationTitle("Create profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavTitle("Create profile")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign out") {
                    appState.signOut()
                }
            }
        }
    }
}

struct CreateProfileView: View {
    var body: some View {
        CreateProfileBody()
    }
}

struct CreateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CreateProfileView()
            .environmentObject(AppState(apiClient: APIClient()))
    }
}
