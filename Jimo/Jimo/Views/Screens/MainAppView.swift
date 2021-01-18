//
//  MainAppView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI

class TabBar: ObservableObject {
    let newPostIndex = 3
    
    @Published var newPostSelected = false
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
    @EnvironmentObject var appState: AppState
    @StateObject var tabBar = TabBar()
    
    let profileVM: ProfileVM
    
    var body: some View {
        TabView(selection: $tabBar.selection) {
            Feed()
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
            ProfileTab(profileVM: profileVM)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(5)
        }
        .sheet(isPresented: $tabBar.newPostSelected) {
            return CreatePost(presented: $tabBar.newPostSelected)
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }
}

//struct MainAppView_Previews: PreviewProvider {
//    static let model = AppModel()
//    static var previews: some View {
//        MainAppView(profileVM: ProfileVM(model: model, username: "gautam"))
//    }
//}
