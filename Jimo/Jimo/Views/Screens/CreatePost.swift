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
            Spacer()
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
            HStack {
                Category(name: "Food", selected: $category)
                Category(name: "Activity", selected: $category)
                Category(name: "Attraction", selected: $category)
                Category(name: "Lodging", selected: $category)
                Category(name: "Shopping", selected: $category)
            }
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


class CreatePostVM: ObservableObject {
    /// 4 cases: (1) name and location from apple, (2) name from apple but custom location, (3) custom name but location from apple,  (4) both custom
    
    var mapRegion: MKCoordinateRegion {
        let location = useCustomLocation ? customLocation : selectedLocation
        if let place = location {
            return MKCoordinateRegion(
                center: place.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        } else {
            return defaultRegion
        }
    }
    
    /// If true, either case 2 or case 4
    @Published var useCustomLocation = false
    
    /// Used for navigation links
    @Published var placeSearchActive = false
    @Published var locationSearchActive = false
    
    /// Photo selection
    @Published var showImagePicker = false
    @Published var image: UIImage?
    
    // Sent to server
    @Published var name: String? = nil
    
    /// Set when user searches and selects a location
    /// If non-nil, then case 1 or 3
    @Published var selectedLocation: MKPlacemark? = nil
    @Published var customLocation: MKPlacemark? = nil
    
    var locationString: String? {
        return useCustomLocation ? "Custom location (View on map)" : selectedPlaceAddress
    }
    
    var selectedPlaceAddress: String? {
        /// For whatever reason, the default placemark title is "United States"
        /// Example: Mount Everest Base Camp has placemark title "United States"
        /// WTF Apple
        if selectedLocation?.title == "United States" {
            return "View on map"
        }
        return selectedLocation?.title
    }
    
    var maybeCreatePlaceRequest: MaybeCreatePlaceRequest? {
        guard let name = name, let location = selectedLocation else {
            return nil
        }
        var region: Region? = nil
        if let placemark = selectedLocation,
           let area = placemark.region as? CLCircularRegion {
            region = Region(coord: placemark.coordinate, radius: area.radius.magnitude)
        }
        return MaybeCreatePlaceRequest(name: name, location: Location(coord: location.coordinate), region: region)
    }
    
    func selectPlace(placeSelection: MKMapItem) {
        useCustomLocation = false
        selectedLocation = placeSelection.placemark
        name = placeSelection.name
    }
    
    func selectLocation(selectionRegion: MKCoordinateRegion) {
        customLocation = MKPlacemark(coordinate: selectionRegion.center)
        useCustomLocation = true
    }
    
    func resetName() {
        name = nil
    }
    
    func resetLocation() {
        if useCustomLocation {
            useCustomLocation = false
            customLocation = nil
        } else {
            // Either there is no searched location or we are already on it
            // In that case clear the location and the search
            selectedLocation = nil
        }
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
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var postModel: PostModel
    @StateObject var createPostVM = CreatePostVM()
    
    @Binding var presented: Bool
    
    @State var category: String? = nil
    @State var content: String = ""
    
    @State var showError = false
    @State var errorMessage = ""
    
    @State var showSuccess = false
    @State var successMessage = "Success!"
    
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
        postModel.createPost(createPostRequest, then: { error in
            if error == nil {
                showSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    presented = false
                }
            } else {
                errorMessage = "Could not create post"
                showError = true
            }
        })
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    CategoryPicker(category: $category)
                        .padding()
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
                        
                        ZStack(alignment: .top) {
                            if let image = createPostVM.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 340, height: 200)
                                    .cornerRadius(20)
                                    .contentShape(Rectangle())
                                RoundedButton(text: Text("Remove"), action: {
                                    createPostVM.image = nil
                                }, backgroundColor: buttonColor)
                                .frame(width: 100, height: 30)
                                .padding(.top, 10)
                            } else {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.gray.opacity(0.2))
                            }
                        }
                        .frame(width: 340, height: 200)
                        // .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .onTapGesture {
                            createPostVM.showImagePicker = true
                        }
                    }
                    Spacer()
                    
                    RoundedButton(text: Text("Add Pin").fontWeight(.bold),
                                  action: self.createPost, backgroundColor: buttonColor)
                        .frame(width: 340, height: 60, alignment: .center)
                        .padding(.bottom, 40)
                    
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
    static var previews: some View {
        CreatePost(presented: .constant(true)).environmentObject(AppModel())
    }
}
