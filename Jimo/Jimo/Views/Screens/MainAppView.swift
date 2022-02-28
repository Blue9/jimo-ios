//
//  MainAppView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI

enum Tab: Int {
    case map = 0, feed = 1, create = 2, search = 3, profile = 4
}

class TabBar: ObservableObject {
    let newPostTag: Tab = .create
    
    @Published var newPostSelected = false
    @Published var selection: Int {
        didSet {
            if selection == newPostTag.rawValue {
                previousSelection = Tab(rawValue: oldValue)
                selection = oldValue
                newPostSelected = true
            }
        }
    }
    
    var previousSelection: Tab?
    
    init() {
        self.selection = Tab.map.rawValue
    }
    
    func reset() {
        if let previousSelection = previousSelection {
            selection = previousSelection.rawValue
        }
    }
}

enum NewPostType {
    case text, full
}

struct MainAppView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @StateObject var tabBar = TabBar()
    
    let currentUser: PublicUser
    
    var body: some View {
        UITabView(selection: $tabBar.selection) {
            MapTab()
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .tabItem("Map", image: UIImage(named: "mapIcon"))
            
            Feed(onCreatePostTap: { tabBar.selection = Tab.create.rawValue })
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .tabItem(
                    "Feed",
                    image: UIImage(named: "feedIcon"),
                    badgeValue: appState.unreadNotifications > 0 ? String(appState.unreadNotifications) : nil
                )
            
            Text("")
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .tabItem("Save", image: UIImage(named: "postIcon"))
            
            Search()
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .tabItem("Discover", image: UIImage(named: "searchIcon"))
            
            ProfileTab(currentUser: currentUser)
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .tabItem("Profile", image: UIImage(named: "profileIcon"))
        }
        .sheet(isPresented: $tabBar.newPostSelected) {
            CreatePost(presented: $tabBar.newPostSelected)
                .environmentObject(appState)
                .environmentObject(globalViewState)
        }
        .accentColor(Color("foreground"))
        .onAppear {
            UITabBar.appearance().shadowImage = UIImage()
            UITabBar.appearance().backgroundImage = UIImage()
            UITabBar.appearance().barTintColor = UIColor(Color("background"))
            UITabBar.appearance().backgroundColor = UIColor(Color("background"))
        }
    }
}
