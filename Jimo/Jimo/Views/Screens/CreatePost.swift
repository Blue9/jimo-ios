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
    var imageName: String
    var color: CGColor
    @Binding var selected: String
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(self.selected == name ? Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.09685359589)) : .clear)
                    .frame(width: 60, height: 90, alignment: .leading)
                VStack {
                    Image(imageName)
                        .frame(width: 60, height: 60, alignment: .center)
                        .background(Color(color))
                        .cornerRadius(15)
                    Text(name)
                        .font(.caption)
                }
            }
            Spacer()
        }
        .onTapGesture {
            self.selected = name
        }
    }
}

struct CategoryPicker: View {
    @Binding var category: String
    
    var body: some View {
        VStack {
            HStack {
                Text("Category")
                    .fontWeight(.bold)
                Spacer()
            }
            HStack {
                Category(name: "Food", imageName: "food", color: #colorLiteral(red: 0.9450980392, green: 0.4941176471, blue: 0.3960784314, alpha: 1), selected: $category)
                Category(name: "Activity", imageName: "activity", color: #colorLiteral(red: 0.6, green: 0.7333333333, blue: 0.3137254902, alpha: 1), selected: $category)
                Category(name: "Attraction", imageName: "attractions", color: #colorLiteral(red: 0.3294117647, green: 0.7254901961, blue: 0.7098039216, alpha: 1), selected: $category)
                Category(name: "Lodging", imageName: "lodging", color: #colorLiteral(red: 0.9843137255, green: 0.7294117647, blue: 0.462745098, alpha: 1), selected: $category)
                Category(name: "Shopping", imageName: "shopping", color: #colorLiteral(red: 1, green: 0.6, blue: 0.7568627451, alpha: 1), selected: $category)
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
            .fontWeight(content != nil ? .semibold : .medium)
            .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
            .padding(.leading)
            .padding(.trailing, 40)
            .foregroundColor(content != nil ? .black : Color(#colorLiteral(red: 0.5098039216, green: 0.5098039216, blue: 0.5098039216, alpha: 1)))
            .background(Color(#colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9529411765, alpha: 1)))
            .overlay(Rectangle().frame(height: 1, alignment: .top).foregroundColor(Color(#colorLiteral(red: 0.7843137255, green: 0.7843137255, blue: 0.7843137255, alpha: 1))), alignment: .top)
            .overlay(Rectangle().frame(height: 1, alignment: .bottom).foregroundColor(Color(#colorLiteral(red: 0.7843137255, green: 0.7843137255, blue: 0.7843137255, alpha: 1))), alignment: .bottom)
            .overlay(content == nil ? nil : Button(action: clearAction) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.gray)
                    .padding(.trailing)
            }, alignment: .trailing)
            .padding(.bottom, 5)
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
            .background(Color(#colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9529411765, alpha: 1)))
            .overlay(Rectangle().frame(height: 1, alignment: .top).foregroundColor(Color(#colorLiteral(red: 0.7843137255, green: 0.7843137255, blue: 0.7843137255, alpha: 1))), alignment: .top)
            .overlay(Rectangle().frame(height: 1, alignment: .bottom).foregroundColor(Color(#colorLiteral(red: 0.7843137255, green: 0.7843137255, blue: 0.7843137255, alpha: 1))), alignment: .bottom)
            .padding(.bottom, 5)
    }
}


class CreatePostVM: ObservableObject {
    /// 4 cases: (1) name and location from apple, (2) name from apple but custom location, (3) custom name but location from apple,  (4) both custom
    
    var mapRegion: MKCoordinateRegion {
        if let place = location {
            return MKCoordinateRegion(
                center: place.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        } else {
            return defaultRegion
        }
    }
    
    /// Set when user searches and selects a location
    /// If non-nil, then case 1 or 3
    var lastSearchedPlace: MKMapItem? = nil
    
    /// If true, either case 2 or case 4
    @Published var customLocation = false
    @Published var placeSearchActive = false
    @Published var locationSearchActive = false
    
    // Sent to server
    @Published var name: String? = nil
    @Published var location: MKPlacemark? = nil
    
    var locationString: String? {
        return customLocation ? "Custom location (View on map)" : lastSearchedPlaceAddress
    }
    
    var lastSearchedPlaceAddress: String? {
        /// For whatever reason, the default placemark title is "United States"
        /// Example: Mount Everest Base Camp has placemark title "United States"
        /// WTF Apple
        if lastSearchedPlace?.placemark.title == "United States" {
            return "View on map"
        }
        return lastSearchedPlace?.placemark.title
    }
    
    func selectPlace(placeSelection: MKMapItem) {
        customLocation = false
        lastSearchedPlace = placeSelection
        location = placeSelection.placemark
        name = placeSelection.name
    }
    
    func selectLocation(selectionRegion: MKCoordinateRegion) {
        location = MKPlacemark(coordinate: selectionRegion.center)
        customLocation = true
    }
    
    func resetName() {
        name = nil
    }
    
    func resetLocation() {
        if customLocation, let place = lastSearchedPlace {
            customLocation = false
            location = place.placemark
        } else {
            // Either there is no searched location or we are already on it
            // In that case clear the location and the search
            customLocation = false
            location = nil
            lastSearchedPlace = nil
        }
    }
}


struct CreatePost: View {
    @State var category: String = ""
    @State var content: String = ""
    @ObservedObject var createPostVM = CreatePostVM()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                CategoryPicker(category: $category)
                    .padding()
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
                FormInputText(name: "Content", text: $content)
                FormInputButton(name: "Photo (Optional)", clearAction: {})
                Spacer()
                RoundedButton(text: "Add Pin", action: {})
                    .padding(.bottom, 40)
            }
            .navigationBarTitle("Create Post", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { self.presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct CreatePost_Previews: PreviewProvider {
    static var previews: some View {
        CreatePost()
    }
}
