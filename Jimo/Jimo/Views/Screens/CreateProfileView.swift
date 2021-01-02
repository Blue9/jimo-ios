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
    
    var valid: Bool {
        isValid(value)
    }
    
    var body: some View {
        let field = TextField(placeholder, text: $value)
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
    @EnvironmentObject var model: AppModel
    
    static let usernameReq = "Usernames should be 3-20 characters"
    static let nameReq = "Required field"
    
    @State var requestError = ""
    static let serverError = "Unknown server error, try again later"
    
    @State var username: String = ""
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var privateAccount = false
    
    @State var showServerError = false
    @State var showRequestError = false
    
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
        model.createUser(request, onComplete: { (response, error) in
            if error != nil {
                showServerError = true
            }
            if let error = response?.error {
                if let usernameError = error.username {
                    requestError = usernameError
                } else if let firstNameError = error.firstName {
                    requestError = firstNameError
                } else if let lastNameError = error.lastName {
                    requestError = lastNameError
                }
                showRequestError = true
            }
            else if let user = response?.created {
                DispatchQueue.main.async {
                    model.currentUser = user
                }
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
                      })
                
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
        .navigationTitle("Create profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign out") {
                    model.signOut()
                }
            }
        }
    }
}

struct CreateProfileView: View {
    var body: some View {
        NavigationView {
            CreateProfileBody()
        }
    }
}

struct CreateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CreateProfileView().environmentObject(AppModel())
    }
}
