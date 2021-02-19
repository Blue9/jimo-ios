//
//  MainAppView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI

class TabBar: ObservableObject {
    let newPostTag = 3
    
    @Published var newPostSelected = false
    var previousSelection: Int
    
    @Published var selection: Int {
        didSet {
            if selection == newPostTag {
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
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    @StateObject var tabBar = TabBar()
    
    let profileVM: ProfileVM
    let mapVM: MapViewModel
    
    var body: some View {
        ZStack {
            TabView(selection: $tabBar.selection) {
                Feed()
                    .tabItem {
                        Image("feedIcon")
                        Text("Home")
                    }
                    .tag(1)
                MapTab(mapModel: appState.mapModel, mapViewModel: mapVM)
                    .tabItem {
                        Image("mapIcon")
                        Text("Map")
                    }
                    .tag(2)
                Text("")
                    .tabItem {
                        Image("postIcon")
                        Text("New")
                    }
                    .tag(3)
                Search()
                    .tabItem {
                        Image("searchIcon")
                        Text("Search")
                    }
                    .tag(4)
                ProfileTab(profileVM: profileVM)
                    .tabItem {
                        Image("profileIcon")
                        Text("Profile")
                    }
                    .tag(5)
            }
        }
        .sheet(isPresented: $tabBar.newPostSelected) {
            return CreatePost(presented: $tabBar.newPostSelected)
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .environment(\.backgroundColor, backgroundColor)
                .preferredColorScheme(.light)
        }
        .accentColor(.black)
        .onAppear {
            UITabBar.appearance().barTintColor = .white
        }
    }
}

//struct MainAppView_Previews: PreviewProvider {
//    static let model = AppModel()
//    static var previews: some View {
//        MainAppView(profileVM: ProfileVM(model: model, username: "gautam"))
//    }
//}
