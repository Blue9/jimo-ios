//
//  CreateProfileView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/12/20.
//

import SwiftUI
import Combine

private let usernameRegex = #"[a-zA-Z0-9_]+"#

struct CreateProfileView: View {
    @EnvironmentObject var appState: AppState

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    if let image = viewModel.profilePicture {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()

                        Button {
                            viewModel.profilePicture = nil
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
                            .foregroundColor(Color("background"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 60)
                                    .stroke(Color("lightgray"), lineWidth: 4)
                            )
                        Text("Add Photo")
                            .font(.system(size: 16))
                            .padding(.top, 45)
                    }
                }
                .frame(width: 120, height: 120)
                .cornerRadius(60)
                .onTapGesture {
                    viewModel.showImagePicker = true
                }
                .padding(.bottom, 40)

                Field(value: $viewModel.username, placeholder: "Username",
                      errorMessage: ViewModel.usernameReq,
                      isValid: viewModel.validUsername,
                      inputFilter: { username in
                        if let range = username.range(
                            of: usernameRegex,
                            options: .regularExpression) {
                            return String(username[range])
                        }
                        return ""
                      },
                      autocapitalization: .none)

                Field(value: $viewModel.firstName, placeholder: "First name",
                      errorMessage: ViewModel.nameReq,
                      isValid: viewModel.validName)

                Field(value: $viewModel.lastName, placeholder: "Last name",
                      errorMessage: ViewModel.nameReq,
                      isValid: viewModel.validName)

                Spacer()

                Button(action: {
                    viewModel.createProfile(appState: appState)
                }) {
                    Text("Create Profile")
                        .font(.system(size: 24))
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 60)
                        .foregroundColor(Color("food"))
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 4))
                                .background(Color("background"))
                        )
                        .cornerRadius(10)
                }
                .buttonStyle(RaisedButtonStyle())
                .disabled(!viewModel.allValid || viewModel.creatingProfile)
                .padding(.bottom, 40)
            }
            .gesture(DragGesture(minimumDistance: 10).onChanged { _ in hideKeyboard() })
            .padding(.horizontal, 24)
            .background(Color("background").edgesIgnoringSafeArea(.all))
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(image: $viewModel.profilePicture, allowsEditing: true)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .popup(isPresented: $viewModel.showServerError, type: .toast, position: .bottom, autohideIn: 2) {
            Toast(text: "Unknown server error. Try again later.", type: .error)
        }
        .popup(isPresented: $viewModel.showRequestError, type: .toast, position: .bottom, autohideIn: 2) {
            Toast(text: viewModel.requestError, type: .warning)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(Color("background")))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign out") {
                    appState.signOut()
                }
            }
        }
        .trackScreen(.createProfile)
    }
}

private struct Field: View {
    static let checkmarkSize: CGFloat = 25

    @Binding var value: String

    let placeholder: String
    let errorMessage: String
    let isValid: (String) -> Bool

    var inputFilter: ((String) -> String)?
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

extension CreateProfileView {
    class ViewModel: ObservableObject {
        static let usernameReq = "Usernames should be 3-20 characters"
        static let nameReq = "Required field"
        static let serverError = "Unknown server error, try again later"

        private var cancelBag: Set<AnyCancellable> = .init()

        @Published var requestError = ""

        @Published var profilePicture: UIImage?
        @Published var username: String = ""
        @Published var firstName: String = ""
        @Published var lastName: String = ""
        @Published var privateAccount = false

        @Published var showImagePicker = false
        @Published var showServerError = false
        @Published var showRequestError = false

        @Published var creatingProfile = false

        var allValid: Bool {
            validUsername(username: username) &&
                validName(name: firstName) &&
                validName(name: lastName)
        }

        func validUsername(username: String) -> Bool {
            return username.count >= 3 && username.count <= 20
        }

        func validName(name: String) -> Bool {
            return name.count > 0 && name.count < 120
        }

        func createProfile(appState: AppState) {
            creatingProfile = true
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
            apiRequest
                .sink(receiveCompletion: { [weak self] completion in
                    self?.creatingProfile = false
                    if case .failure = completion {
                        self?.showServerError = true
                    }
                }, receiveValue: { [weak self] error in
                    if let error = error {
                        if let uidError = error.uid {
                            self?.requestError = uidError
                        } else if let usernameError = error.username {
                            self?.requestError = usernameError
                        } else if let firstNameError = error.firstName {
                            self?.requestError = firstNameError
                        } else if let lastNameError = error.lastName {
                            self?.requestError = lastNameError
                        } else if let otherError = error.other {
                            self?.requestError = otherError
                        } else {
                            self?.requestError = "Unknown error"
                        }
                        self?.showRequestError = true
                    }
                })
                .store(in: &cancelBag)
        }
    }
}
