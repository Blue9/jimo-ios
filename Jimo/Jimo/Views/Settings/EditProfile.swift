//
//  EditProfile.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/13/21.
//

import SwiftUI
import Combine

struct EditProfile: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @StateObject private var viewModel = ViewModel()
    
    var buttonDisabled: Bool {
        !viewModel.initialized || !viewModel.edited || viewModel.updating
    }
    
    var body: some View {
        Form {
            
            ZStack(alignment: .trailing) {
                HStack {
                    Spacer()
                    
                    Group {
                        if let image = viewModel.image {
                            Image(uiImage: image)
                                .resizable()
                        } else {
                            URLImage(url: viewModel.profilePictureUrl,
                                     loading: Image(systemName: "person.crop.circle").resizable())
                                .foregroundColor(.gray)
                                .background(Color.white)
                        }
                    }
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .cornerRadius(60)
                    .onTapGesture {
                        viewModel.showImagePicker = true
                    }
                    
                    Spacer()
                }
                
                if viewModel.image != nil {
                    Text("Reset")
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.init(white: 0.7))
                        .cornerRadius(50)
                        .onTapGesture {
                            viewModel.image = nil
                        }
                }
            }
            
            HStack(spacing: 10) {
                Text("Username").bold()
                TextField("Username", text: $viewModel.username)
                    .autocapitalization(.none)
            }
            
            HStack(spacing: 10) {
                Text("First name").bold()
                TextField("First name", text: $viewModel.firstName)
            }
            
            HStack(spacing: 10) {
                Text("Last name").bold()
                TextField("Last name", text: $viewModel.lastName)
            }
            
            Section {
                Button(action: { viewModel.updateProfile(
                        appState: appState, viewState: globalViewState)}) {
                    if viewModel.updating {
                        ProgressView()
                    } else {
                        Text("Save changes")
                            .foregroundColor(buttonDisabled ? .gray : .blue)
                    }
                }
                .disabled(buttonDisabled)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            viewModel.initialize(appState: appState)
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(image: $viewModel.image, allowsEditing: true)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(Color("background")))
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavTitle("Edit profile")
            }
        }
    }
}

extension EditProfile {
    class ViewModel: ObservableObject {
        @Published var username: String = "" { didSet { edited = true } }
        @Published var firstName: String = "" { didSet { edited = true } }
        @Published var lastName: String = "" { didSet { edited = true } }
        @Published var profilePictureUrl: String? = nil
        
        @Published var showImagePicker = false
        @Published var image: UIImage? = nil {
            didSet {
                if image != nil {
                    edited = true
                }
            }
        }
        
        @Published var edited = false
        @Published var initialized = false
        
        @Published var updating = false
        
        private var cancellable: Cancellable? = nil
        private var uploadImageCancellable: Cancellable? = nil
        
        func initialize(appState: AppState) {
            guard case let .user(user) = appState.currentUser else {
                return
            }
            username = user.username
            firstName = user.firstName
            lastName = user.lastName
            profilePictureUrl = user.profilePictureUrl
            initialized = true
            edited = false
        }
        
        func updateProfile(appState: AppState, viewState: GlobalViewState) {
            DispatchQueue.main.async {
                self.updating = true
            }
            hideKeyboard()
            if let image = image {
                uploadImageCancellable = appState.uploadImageAndGetId(image: image)
                    .sink(receiveCompletion: { [weak self] completion in
                        if case let .failure(error) = completion {
                            print("Error when uploading image", error)
                            viewState.setError("Error when uploading image. Try again.")
                            self?.updating = false
                        }
                    }, receiveValue: { [weak self] imageId in
                        self?.updateProfile(appState: appState, viewState: viewState, profilePictureId: imageId)
                    })
            } else {
                self.updateProfile(appState: appState, viewState: viewState, profilePictureId: nil)
            }
        }
        
        private func updateProfile(appState: AppState, viewState: GlobalViewState, profilePictureId: String?) {
            cancellable = appState.updateProfile(
                UpdateProfileRequest(
                    profilePictureId: profilePictureId,
                    username: username,
                    firstName: firstName,
                    lastName: lastName))
                .sink(receiveCompletion: { [weak self] completion in
                    self?.updating = false
                    if case let .failure(error) = completion {
                        print("Error when updating user", error)
                        if case let .requestError(maybeErrors) = error,
                           let errors = maybeErrors,
                           let first = errors.first {
                            viewState.setWarning(first.value)
                        } else {
                            viewState.setError("Could not update user")
                        }
                    }
                }, receiveValue: { response in
                    if let error = response.error {
                        if let uidError = error.uid {
                            viewState.setWarning(uidError)
                        } else if let usernameError = error.username {
                            viewState.setWarning(usernameError)
                        } else if let firstNameError = error.firstName {
                            viewState.setWarning(firstNameError)
                        } else if let lastNameError = error.lastName {
                            viewState.setWarning(lastNameError)
                        } else if let otherError = error.other {
                            viewState.setError(otherError)
                        } else {
                            viewState.setError("Could not update user")
                        }
                    } else if response.user != nil {
                        viewState.setSuccess("Updated profile!")
                    }
                })
        }
    }
}
