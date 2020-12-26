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
            .background(RoundedRectangle(cornerRadius: 25)
                            .stroke(style: StrokeStyle(lineWidth: 4))
                            .foregroundColor(.blue))
        
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

struct CreateProfileView: View {
    @EnvironmentObject var model: AppModel
    
    @State var username: String = ""
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var privateAccount = false
    
    static let usernameError = "Usernames should be 3-20 characters"
    static let nameError = "Required field"
    
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
        model.signOut()
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Almost there!")
            
            Field(value: $username, placeholder: "Username",
                  errorMessage: CreateProfileView.usernameError,
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
                  errorMessage: CreateProfileView.nameError,
                  isValid: self.validName)
            
            Field(value: $lastName, placeholder: "Last name",
                  errorMessage: CreateProfileView.nameError,
                  isValid: self.validName)
            
            Toggle(isOn: $privateAccount) {
                Text("Private account")
            }
            
            Button(action: createProfile) {
                Text("Create my profile (sign out)")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.white)
                    .background(allValid ? Color.green : Color.gray)
                    .cornerRadius(25)
            }
            .disabled(!allValid)
        }
        .padding(.horizontal, 48)
        .navigationTitle("Create profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CreateProfileView().environmentObject(AppModel())
    }
}
