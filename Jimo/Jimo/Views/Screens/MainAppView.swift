//
//  MainAppView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI
import FirebaseAnalytics

enum Tab: Int {
    case map = 0, feed = 1, create = 2, search = 3, profile = 4
    var string: String {
        switch self {
            case .feed:
                return "feed"
            case .map:
                return "map"
            case .create:
                return "create"
            case .search:
                return "search"
            case .profile:
                return "profile"
        }
    }
}

class TabBar: ObservableObject {
    let newPostTag: Tab = .create
    
    @Published var newPostSelected = false
    @Published var selection: Int {
        didSet {
            previousSelection = Tab(rawValue: oldValue)
            if selection == newPostTag.rawValue {
                previousSelection = Tab(rawValue: oldValue)
                selection = oldValue
                newPostSelected = true
            } else if String(oldValue) == "2"{
                ()
            } else if String(oldValue) != "2" {
                logTabSelection(tab: Tab(rawValue: selection)!)
            }

        }
    }
    
    var previousSelection: Tab?
    
    init() {
        self.selection = Tab.map.rawValue
        logTabSelection(tab: Tab.map)
    }
    
    func reset() {
        if let previousSelection = previousSelection {
            selection = previousSelection.rawValue
        }
    }
    
    private func logTabSelection(tab: Tab) {
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [AnalyticsParameterScreenName: tab.string, AnalyticsParameterScreenClass: tab.string]
            )
        print(">>> current tab", tab.string)
    }
    
    private func logCreatePostTab() {
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [AnalyticsParameterScreenName: "create", AnalyticsParameterScreenClass: "create"]
            )
        print(">>> current tab create")
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
