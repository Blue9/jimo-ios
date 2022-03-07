//
//  CreatePost.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI
import MapKit
import Combine
import FirebaseAnalytics


struct CreatePostCategory: View {
    var name: String
    var key: String
    @Binding var selected: String?
    
    var colored: Bool {
        selected == nil || selected == key
    }
    
    var body: some View {
        HStack {
            Image(key)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 35, maxHeight: 35)
            
            Spacer()
            
            Text(name)
                .font(.system(size: 15))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7.5)
        .background(colored ? Color(key) : Color("unselected"))
        .cornerRadius(2)
        .shadow(radius: colored ? 5 : 0)
        .frame(height: 50)
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
                    .font(.system(size: 15))
                    .bold()
                Spacer()
            }
            
            VStack {
                HStack {
                    CreatePostCategory(name: "Food", key: "food", selected: $category)
                    CreatePostCategory(name: "Things to do", key: "activity", selected: $category)
                }
                
                HStack {
                    CreatePostCategory(name: "Nightlife", key: "nightlife", selected: $category)
                    CreatePostCategory(name: "Things to see", key: "attraction", selected: $category)
                }
                
                HStack {
                    CreatePostCategory(name: "Lodging", key: "lodging", selected: $category)
                    CreatePostCategory(name: "Shopping", key: "shopping", selected: $category)
                }
            }
        }
        .padding(.horizontal, 10)
    }
}

struct FormInputButton: View {
    var name: String
    var content: String? = nil
    var destination: AnyView?
    var clearAction: () -> Void
    
    @ViewBuilder var clearInputView: some View {
        Button(action: clearAction) {
            Image(systemName: "xmark.circle")
                .foregroundColor(.gray)
                .padding(.trailing)
        }
    }
    
    @ViewBuilder var rightArrow: some View {
        Image(systemName: "chevron.right")
            .foregroundColor(.gray)
            .padding(.trailing)
    }
    
    var body: some View {
        Group {
            if let content = content {
                Text(name + ": ").font(.system(size: 15)).bold()
                + Text(content).font(.system(size: 15))
            } else {
                Text(name).font(.system(size: 15)).bold()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundColor(Color("foreground"))
        .overlay(content == nil ? AnyView(rightArrow) : AnyView(clearInputView), alignment: .trailing)
        .multilineTextAlignment(.leading)
    }
}

struct FormInputText: View {
    var name: String
    var height: CGFloat = 100
    @Binding var text: String
    
    var body: some View {
        MultilineTextField(name, text: $text, height: height)
            .font(.system(size: 15))
    }
}


struct CreatePostDivider: View {
    var body: some View {
        Divider()
            .background(Color.gray)
            .padding(.horizontal, 15)
    }
}


struct MapPreview: View {
    @EnvironmentObject var appState: AppState
    
    var category: String?
    var place: MKMapItem
    
    let defaultSpan: CLLocationDegrees = 4
    let width = UIScreen.main.bounds.width - 20
    let height: CGFloat = 200
    
    @State private var snapshotImage: UIImage? = nil
    
    var currentUserProfilePicture: String? {
        if case let .user(user) = appState.currentUser {
            return user.profilePictureUrl
        }
        return nil
    }
    
    var span: CGFloat {
        if let region = place.placemark.region as? CLCircularRegion {
            return min(region.radius * 10, 200000) / 111111
        } else {
            return defaultSpan
        }
    }
    
    func generateSnapshot(width: CGFloat, height: CGFloat) {
        // The region the map should display.
        let region = MKCoordinateRegion(
            center: place.placemark.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: span,
                longitudeDelta: span
            )
        )
        
        // Map options.
        let mapOptions = MKMapSnapshotter.Options()
        mapOptions.region = region
        mapOptions.size = CGSize(width: width, height: height)
        mapOptions.showsBuildings = false
        
        // Create the snapshotter and run it.
        let snapshotter = MKMapSnapshotter(options: mapOptions)
        snapshotter.start { (snapshotOrNil, errorOrNil) in
            if let error = errorOrNil {
                print(error)
                return
            }
            if let snapshot = snapshotOrNil {
                self.snapshotImage = snapshot.image
            }
        }
    }
    
    var body: some View {
        ZStack {
            Group {
                if let image = snapshotImage {
                    Image(uiImage: image)
                } else {
                    Color.init(red: 250 / 255, green: 245 / 255, blue: 241 / 255)
                }
            }
            
            Circle()
                .fill()
                .frame(width: 40, height: 40)
                .foregroundColor(category != nil ? Color(category!) : .gray)
            
            URLImage(
                url: currentUserProfilePicture,
                loading: Image(systemName: "person.crop.circle"),
                thumbnail: true
            )
                .foregroundColor(.gray)
                .frame(width: 35, height: 35)
                .background(Color.white)
                .cornerRadius(17.5)
        }
        .onAppear {
            generateSnapshot(width: width, height: height)
        }
    }
}

struct CreatePost: View {
    @StateObject var createPostVM = CreatePostVM()
    @Binding var presented: Bool
    
    var body: some View {
        CreatePostWithModel(createPostVM: createPostVM, presented: $presented)
    }
}

struct CreatePostWithModel: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var createPostVM: CreatePostVM
    
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
            errorMessage = "Location is required"
            showError = true
            return
        }
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
                                                          imageId: imageId))
                })
                .eraseToAnyPublisher()
        } else {
            let createPostRequest = CreatePostRequest(
                place: createPlaceRequest,
                category: category,
                content: content,
                imageId: nil)
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
                        self.errorMessage = "Could not save place"
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
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Save a place")
                            .font(.system(size: 28))
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                        
                        Divider().padding(.leading, 10)
                        
                        Group {
                            Button(action: { createPostVM.activeSheet = .placeSearch
                            print(">>> enter_location")
                            Analytics.logEvent("enter_location", parameters: nil)
                            }) {
                                FormInputButton(
                                    name: "Enter location",
                                    content: createPostVM.name,
                                    clearAction: createPostVM.resetPlace)
                            }
                        }
                        .frame(height: 40)
                        .padding(.horizontal, 10)
                        
                        Divider().padding(.leading, 10)
                        
                        HStack {
                            ImageSelectionView(createPostVM: createPostVM, buttonColor: buttonColor)
                            
                            FormInputText(name: "Write a note (recommended)", text: $content)
                                .zIndex(2)
                        }
                        .padding(10)
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                        
                        Divider().padding(.leading, 10)
                        
                        CategoryPicker(category: $category)
                            .padding(.vertical, 10)
                            .ignoresSafeArea(.keyboard, edges: .bottom)
                        
                        
                        if let place = createPostVM.selectedLocation {
                            Group {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Preview")
                                        .font(.system(size: 15))
                                        .bold()
                                        .padding(10)
                                    
                                    MapPreview(category: category, place: place)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 200)
                                        .cornerRadius(2)
                                        .padding(.horizontal, 10)
                                }
                            }
                            .id(createPostVM.selectedLocation)
                        }
                        
                        Spacer()
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .foregroundColor(Color("foreground"))
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .background(Color("background").edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(UIColor(Color("background")))
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    Image("logo")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(Color("foreground"))
                        .scaledToFit()
                        .frame(width: 50)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        self.presented.toggle()
                    } label: {
                        Image(systemName: "xmark").foregroundColor(Color("foreground"))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        self.createPost()
                        var image_uploaded_with_post = true
                        if createPostVM.image == nil {
                            image_uploaded_with_post = false
                        }
                        
                        var text_uploaded_with_post = true
                        if content.isEmpty == true {
                            text_uploaded_with_post = false
                        }
                        print(">>> create_post")
                        Analytics.logEvent("create_post", parameters: [
                            "category_chosen": category,
                            "text_uploaded_with_post": text_uploaded_with_post,
                            "image_uploaded_with_post": image_uploaded_with_post
                        
                        ])
                    } label: {
                        Text("Save").bold()
                    }
                }
            })
            .popup(isPresented: $showError, type: .toast, autohideIn: 2) {
                Toast(text: errorMessage, type: .error)
                    .opacity(showError ? 1 : 0)
            }
            .popup(isPresented: $showSuccess, type: .toast, autohideIn: 2) {
                Toast(text: successMessage, type: .success)
                    .opacity(showSuccess ? 1 : 0)
            }
            .sheet(item: $createPostVM.activeSheet) { (activeSheet: CreatePostActiveSheet) in
                Group {
                    switch activeSheet {
                    case .placeSearch:
                        PlaceSearch(selectPlace: createPostVM.selectPlace)
                    case .imagePicker:
                        ImagePicker(image: $createPostVM.image)
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .onChange(of: createPostVM.activeSheet) { activeSheet in
                // Bug where if the keyboard is up and the sheet changes from image picker back to create post, tapping
                // a category is offset
                hideKeyboard()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ImageSelectionView: View {
    @ObservedObject var createPostVM: CreatePostVM
    
    var buttonColor: Color
    
    var body: some View {
        Group {
            if let image = createPostVM.image {
                ZStack(alignment: .topLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .onTapGesture {
                            createPostVM.activeSheet = .imagePicker
                        }
                    
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(buttonColor)
                        .background(Color.black)
                        .cornerRadius(10)
                        .padding(5)
                        .onTapGesture {
                            createPostVM.image = nil
                        }
                }
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .onTapGesture {
                            createPostVM.activeSheet = .imagePicker
                        }
                    
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .foregroundColor(Color.gray.opacity(0.5))
                }
            }
        }
        .frame(width: 100, height: 100)
        .cornerRadius(2)
    }
}
