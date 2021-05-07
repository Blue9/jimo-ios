//
//  CreatePost.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI
import MapKit
import Combine


struct Category: View {
    var name: String
    var spacerAfter = true
    var key: String {
        name.lowercased()
    }
    @Binding var selected: String?
    
    var colored: Bool {
        selected == nil || selected == key
    }
    
    var body: some View {
        HStack {
            VStack {
                Image(key)
                    .frame(width: 60, height: 60, alignment: .center)
                    .background(colored ? Color(key) : Color("unselected"))
                    .cornerRadius(15)
                    .shadow(radius: colored ? 5 : 0)
                Text(name)
                    .font(.caption)
            }
            
            if spacerAfter {
                Spacer()
            }
        }
        .onTapGesture {
            self.selected = key
        }
    }
}

struct CategoryPicker: View {
    @Binding var category: String?
    
    var body: some View {
        VStack {
            HStack {
                Text("Select category")
                    .font(Font.custom(Poppins.semiBold, size: 16))
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                Spacer()
                
                HStack {
                    Spacer()
                    Category(name: "Food", selected: $category)
                    Category(name: "Activity", selected: $category)
                    Category(name: "Attraction", selected: $category)
                    Category(name: "Lodging", selected: $category)
                    Category(name: "Shopping", spacerAfter: false, selected: $category)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .frame(minWidth: UIScreen.main.bounds.width)
                
                Spacer()
            }
            .frame(height: 82)
            .frame(maxWidth: .infinity)
        }
    }
}


struct FormInputButton: View {
    var name: String
    var content: String? = nil
    var destination: AnyView?
    var clearAction: () -> Void
    
    var body: some View {
        Group {
            if let content = content {
                Text(name + ": ").font(Font.custom(Poppins.medium, size: 15))
                    + Text(content).font(Font.custom(Poppins.regular, size: 15))
            } else {
                Text(name).font(Font.custom(Poppins.medium, size: 15))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading)
        .padding(.trailing, 40)
        .padding(.vertical, 12)
        .foregroundColor(.black)
        .overlay(content == nil ? nil : Button(action: clearAction) {
            Image(systemName: "xmark.circle")
                .foregroundColor(.gray)
                .padding(.trailing)
        }, alignment: .trailing)
    }
}

struct FormInputText: View {
    var name: String
    var height: CGFloat = 100
    @Binding var text: String
    
    var body: some View {
        MultilineTextField(name, text: $text, height: height)
            .font(Font.custom(Poppins.regular, size: 15))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .padding(.bottom, 8)
    }
}


struct CreatePostDivider: View {
    var body: some View {
        Divider()
            .background(Color.gray)
            .padding(.horizontal, 15)
    }
}


struct CreatePost: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.backgroundColor) var backgroundColor
    @StateObject var createPostVM = CreatePostVM()
    
    @Binding var presented: Bool
    
    @State private var category: String? = nil
    @State private var content: String = ""
    
    @State private var posting = false
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var showSuccess = false
    @State private var successMessage = "Success!"
    
    var buttonColor: Color {
        if let category = category {
            return Color(category)
        } else {
            return Color(#colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9529411765, alpha: 0.9921568627))
        }
    }
    
    func createPost() {
        hideKeyboard()
        guard let category = category else {
            errorMessage = "Category is required"
            showError = true
            return
        }
        guard let createPlaceRequest = createPostVM.maybeCreatePlaceRequest else {
            errorMessage = "Name and location are required"
            showError = true
            return
        }
        let customLocation = createPostVM.customLocation.map({ location in Location(coord: location.coordinate) })
        // First upload the image
        posting = true
        var request: AnyPublisher<Void, APIError>
        if let image = createPostVM.image {
            request = appState.uploadImageAndGetId(image: image)
                .catch({ error -> AnyPublisher<ImageId, APIError> in
                    print("Error when uploading image", error)
                    if case let .requestError(error) = error,
                       let first = error?.first {
                        self.errorMessage = first.value
                        self.showError = true
                    } else {
                        self.errorMessage = "Could not upload image."
                        self.showError = true
                    }
                    return Empty().eraseToAnyPublisher()
                })
                .flatMap({ imageId -> AnyPublisher<Void, APIError> in
                    appState.createPost(CreatePostRequest(place: createPlaceRequest,
                                                          category: category,
                                                          content: content,
                                                          imageId: imageId,
                                                          customLocation: customLocation))
                })
                .eraseToAnyPublisher()
        } else {
            let createPostRequest = CreatePostRequest(
                place: createPlaceRequest,
                category: category,
                content: content,
                imageId: nil,
                customLocation: customLocation)
            request = appState.createPost(createPostRequest)
        }
        createPostVM.cancellable = request
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when creating post", error)
                    if case let .requestError(maybeErrors) = error,
                       let errors = maybeErrors,
                       let first = errors.first {
                        self.errorMessage = first.value
                    } else {
                        self.errorMessage = "Could not create post"
                    }
                    self.showError = true
                }
                self.posting = false
            }, receiveValue: {
                self.showSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.presented = false
                }
            })
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        CategoryPicker(category: $category)
                            .padding(.vertical)
                        
                        Group {
                            Button(action: { createPostVM.activeSheet = .placeSearch }) {
                                FormInputButton(
                                    name: "Name",
                                    content: createPostVM.name,
                                    clearAction: createPostVM.resetName)
                            }
                            
                            CreatePostDivider()
                            
                            Button(action: { createPostVM.activeSheet = .locationSelection }) {
                                FormInputButton(
                                    name: "Location",
                                    content: createPostVM.locationString,
                                    clearAction: createPostVM.resetLocation)
                            }
                            
                            CreatePostDivider()
                            
                            FormInputText(name: "Write a note (recommended)", text: $content)
                            
                            CreatePostDivider()
                            
                            FormInputButton(name: "Photo (recommended)", clearAction: {})
                            
                            ZStack(alignment: .topLeading) {
                                if let image = createPostVM.image {
                                    ZStack {
                                        GeometryReader { geometry in
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: geometry.size.height)
                                                .frame(maxWidth: geometry.size.width)
                                        }
                                        .frame(height: 200)
                                    }
                                    .cornerRadius(10)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        createPostVM.activeSheet = .imagePicker
                                    }
                                    
                                    Image(systemName: "xmark.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(buttonColor)
                                        .background(Color.black)
                                        .cornerRadius(15)
                                        .shadow(radius: 5)
                                        .padding(5)
                                        .onTapGesture {
                                            createPostVM.image = nil
                                        }

                                } else {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.gray.opacity(0.2))
                                        .onTapGesture {
                                            createPostVM.activeSheet = .imagePicker
                                        }
                                        .frame(height: 200)
                                        .cornerRadius(10)
                                        .contentShape(Rectangle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                        
                        RoundedButton(text: Text("Add Pin").font(Font.custom(Poppins.semiBold, size: 16)),
                                      action: self.createPost, backgroundColor: buttonColor)
                            .frame(height: 60, alignment: .center)
                            .padding(.horizontal)
                            .padding(.top, 15)
                            .padding(.bottom, 20)
                            .disabled(posting)
                    }
                }
                .gesture(DragGesture().onChanged { _ in hideKeyboard() })
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(UIColor(backgroundColor))
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    NavTitle("New post")
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.presented.toggle()
                    }
                }
            })
            .popup(isPresented: $showError, type: .toast, autohideIn: 2) {
                Toast(text: errorMessage, type: .error)
            }
            .popup(isPresented: $showSuccess, type: .toast, autohideIn: 2) {
                Toast(text: successMessage, type: .success)
            }
            .sheet(item: $createPostVM.activeSheet) { (activeSheet: CreatePostActiveSheet) in
                Group {
                    switch activeSheet {
                    case .placeSearch:
                        PlaceSearch(selectPlace: createPostVM.selectPlace)
                    case .locationSelection:
                        LocationSelection(mapRegion: createPostVM.mapRegion, afterConfirm: createPostVM.selectLocation)
                    case .imagePicker:
                        ImagePicker(image: $createPostVM.image)
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .preferredColorScheme(.light)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct CreatePost_Previews: PreviewProvider {
    static let api = APIClient()
    
    static var previews: some View {
        CreatePost(presented: .constant(true))
            .environmentObject(AppState(apiClient: api))
            .environmentObject(GlobalViewState())
    }
}
