//
//  CreatePost.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI
import MapKit


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
                Text("Category")
                    .fontWeight(.bold)
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
    var height: CGFloat = 50
    var destination: AnyView?
    var clearAction: () -> Void
    
    var body: some View {
        Text(content ?? name)
            .fontWeight(content != nil ? .regular : .medium)
            .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
            .padding(.leading)
            .padding(.trailing, 40)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .padding(.bottom, 5)
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
    @StateObject var createPostVM = CreatePostVM()
    
    @Binding var presented: Bool
    
    @State private var category: String? = nil
    @State private var content: String = ""
    
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
        let createPostRequest = CreatePostRequest(
            place: createPlaceRequest,
            category: category,
            content: content,
            imageUrl: nil,
            customLocation: customLocation)
        createPostVM.cancellable = appState.createPost(createPostRequest)
            .sink(receiveCompletion: { completion in
                if case .failure(_) = completion {
                    self.errorMessage = "Could not create post"
                    self.showError = true
                }
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
                            NavigationLink(
                                destination: PlaceSearch(
                                    active: $createPostVM.placeSearchActive,
                                    selectPlace: createPostVM.selectPlace),
                                isActive: $createPostVM.placeSearchActive) {
                                FormInputButton(
                                    name: "Name",
                                    content: createPostVM.name,
                                    clearAction: createPostVM.resetName)
                            }
                            
                            CreatePostDivider()
                            
                            NavigationLink(
                                destination: LocationSelection(
                                    mapRegion: createPostVM.mapRegion,
                                    active: $createPostVM.locationSearchActive,
                                    afterConfirm: createPostVM.selectLocation),
                                isActive: $createPostVM.locationSearchActive) {
                                FormInputButton(
                                    name: "Location",
                                    content: createPostVM.locationString,
                                    clearAction: createPostVM.resetLocation)
                            }
                            
                            CreatePostDivider()
                            
                            FormInputText(name: "Write a Note (Recommended)", text: $content)
                            
                            CreatePostDivider()
                            
                            FormInputButton(name: "Photo (Recommended)", clearAction: {})
                            
                            ZStack(alignment: .topLeading) {
                                if let image = createPostVM.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 340, height: 200)
                                        .cornerRadius(10)
                                        .contentShape(Rectangle())
                                    
                                    Image(systemName: "xmark.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(buttonColor)
                                        .shadow(radius: 5)
                                        .padding(5)
                                        .onTapGesture {
                                            createPostVM.image = nil
                                        }

                                } else {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.gray.opacity(0.2))
                                }
                            }
                            .frame(height: 200)
                            .frame(maxWidth: 340)
                             .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .onTapGesture {
                                createPostVM.showImagePicker = true
                            }
                        }
                        
                        RoundedButton(text: Text("Add Pin").fontWeight(.bold),
                                      action: self.createPost, backgroundColor: buttonColor)
                            .frame(height: 60, alignment: .center)
                            .frame(maxWidth: 340)
                            .padding(.horizontal, 30)
                            .padding(.top, 40)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
            .sheet(isPresented: $createPostVM.showImagePicker) {
                ImagePicker(image: $createPostVM.image)
                    .preferredColorScheme(.light)
            }
        }
    }
}

struct CreatePost_Previews: PreviewProvider {
    static let api = APIClient()
    
    static var previews: some View {
        CreatePost(presented: .constant(true))
            .environmentObject(AppState(apiClient: api))
    }
}
