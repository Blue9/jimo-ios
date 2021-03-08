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
    static let checkmarkSize: CGFloat = 25

    @Binding var value: String
    
    let placeholder: String
    let errorMessage: String
    let isValid: (String) -> Bool
    
    var inputFilter: ((String) -> String)? = nil
    var autocapitalization: UITextAutocapitalizationType = .words
    
    var valid: Bool {
        isValid(value)
    }

    var accentColor: Color {
        valid ? .green : Color("lightgray")
    }

    var body: some View {

        HStack {
            if let filter = inputFilter {
                TextField(placeholder, text: $value)
                    .autocapitalization(autocapitalization)
                    .onReceive(Just(value)) { newValue in
                        let filtered = filter(newValue)
                        if filtered != newValue {
                            self.value = filtered
                        }
                    }
            } else {
                TextField(placeholder, text: $value)
                    .autocapitalization(autocapitalization)
            }

            Image(systemName: valid ? "checkmark.circle.fill" : "checkmark.circle")
                .resizable()
                .frame(width: Field.checkmarkSize, height: Field.checkmarkSize)
                .foregroundColor(accentColor)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 2)))
    }
}

struct CreateProfileBody: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.backgroundColor) var backgroundColor

    static let usernameReq = "Usernames should be 3-20 characters"
    static let nameReq = "Required field"
    static let serverError = "Unknown server error, try again later"
    
    @State private var cancellable: Cancellable? = nil
    
    @State private var requestError = ""

    @State private var profilePicture: UIImage?
    @State private var username: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var privateAccount = false

    @State private var showImagePicker = false
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
        var apiRequest: AnyPublisher<UserFieldError?, APIError>
        if let image = profilePicture {
            apiRequest = appState.createUser(request, profilePicture: image)
        } else {
            apiRequest = appState.createUser(request)
        }
        cancellable = apiRequest
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    showServerError = true
                }
            }, receiveValue: { error in
                if let error = error {
                    if let uidError = error.uid {
                        requestError = uidError
                    } else if let usernameError = error.username {
                        requestError = usernameError
                    } else if let firstNameError = error.firstName {
                        requestError = firstNameError
                    } else if let lastNameError = error.lastName {
                        requestError = lastNameError
                    } else if let otherError = error.other {
                        requestError = otherError
                    } else {
                        requestError = "Unknown error"
                    }
                    showRequestError = true
                }
            })
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    if let image = profilePicture {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()

                        Button {
                            profilePicture = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                                .frame(width: 30, height: 30)
                                .background(Color.white.cornerRadius(15))
                        }
                        .padding(.leading, 60)
                        .padding(.bottom, 60)
                    } else {
                        Circle()
                            .foregroundColor(backgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 60)
                                    .stroke(Color("lightgray"), lineWidth: 4)
                            )
                        Text("Add Photo")
                            .font(Font.custom(Poppins.regular, size: 16))
                            .padding(.top, 45)
                    }
                }
                .frame(width: 120, height: 120)
                .cornerRadius(60)
                .onTapGesture {
                    showImagePicker = true
                }
                .padding(.bottom, 40)

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

                Spacer()

                Button(action: createProfile) {
                    Text("Create Profile")
                        .font(Font.custom(Poppins.medium, size: 24))
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 60)
                        .foregroundColor(Color("food"))
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 4))
                                .background(Color.white)
                        )
                        .cornerRadius(10)
                }
                .buttonStyle(RaisedButtonStyle())
                .disabled(!allValid)
                .padding(.bottom, 40)
            }
            .gesture(DragGesture(minimumDistance: 10).onChanged { _ in hideKeyboard() })
            .padding(.horizontal, 24)
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $profilePicture, allowsEditing: true)
                .preferredColorScheme(.light)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .popup(isPresented: $showServerError, type: .toast, position: .bottom, autohideIn: 2) {
            Toast(text: "Unknown server error. Try again later.", type: .error)
        }
        .popup(isPresented: $showRequestError, type: .toast, position: .bottom, autohideIn: 2) {
            Toast(text: requestError, type: .warning)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(backgroundColor))
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
            .environmentObject(GlobalViewState())
    }
}
