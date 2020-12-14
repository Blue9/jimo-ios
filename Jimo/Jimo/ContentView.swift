//
//  ContentView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI

class TabBar: ObservableObject {
    let newPostIndex = 3
    
    var newPostSelected = false
    var previousSelection: Int
    
    @Published var selection: Int {
        didSet {
            if selection == newPostIndex {
                previousSelection = oldValue
                selection = oldValue
                newPostSelected = true
            }
        }
    }
    
    func reset() {
        selection = previousSelection
    }
    
    init() {
        self.selection = 1
        self.previousSelection = 1
    }
}

enum NewPostType {
    case text, full
}

struct MainAppView: View {
    @ObservedObject var tabBar = TabBar()
    @State var showNewPostSheet = false
    @State var newPostType: NewPostType = .full
    @EnvironmentObject var model: AppModel
    
    let profileVM: ProfileVM
    
    var body: some View {
        TabView(selection: $tabBar.selection) {
            Text("Home")
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(1)
            MapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
                .tag(2)
            Text("")
                .tabItem {
                    Image(systemName: "plus.square")
                    Text("New")
                }
                .tag(3)
            Search()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(4)
            Profile(profileVM: profileVM)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(5)
        }
        .actionSheet(isPresented: $tabBar.newPostSelected) {
            ActionSheet(title: Text("New post"),
                        message: Text("What type of post would you like to create?"),
                        buttons: [
                            .default(Text("New text post"), action: newTextPost),
                            .default(Text("New recommendation"), action: newRecommendation),
                            .cancel(Text("Cancel"), action: tabBar.reset)])
        }
        .sheet(isPresented: $showNewPostSheet) {
            if newPostType == .text {
                Text("Create text post")
            } else { // newPostType == .full
                CreatePost()
            }
        }
    }
    
    func newTextPost() {
        newPostType = .text
        showNewPostSheet = true
        tabBar.reset()
    }
    
    func newRecommendation() {
        newPostType = .full
        showNewPostSheet = true
        tabBar.reset()
    }
}

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    
    var body: some View {
        ZStack {
            if (!model.initialized) {
                Text("Loading...")
                    .transition(.slide)
            } else if (model.firebaseSession == nil) {
                // Firebase user does not exist
                AuthView()
                    .transition(.slide)
            } else if (model.loadingUserProfile == .loading) {
                Text("Just a sec!")
                    .transition(.opacity)
            } else if (model.loadingUserProfile == .error) {
                Button("Unable to connect to server. Tap here to try again") {
                    model.loadCurrentUserProfile()
                }
                .transition(.opacity)
            } else if (model.currentUser == nil && model.loadingUserProfile == .success) {
                // User profile does not exist
                CreateProfileView()
                    .transition(.slide)
            } else { // both are non-nil
                MainAppView(profileVM: ProfileVM(model: model, username: model.currentUser!.username, user: model.currentUser!))
                    .transition(.slide)
            }
        }
        .onAppear(perform: model.listen)
    }
}

struct ContentView_Previews: PreviewProvider {
    static let sessionStore = SessionStore()
    static let model = AppModel()
    
    static var previews: some View {
        ContentView().environmentObject(model)
    }
}
