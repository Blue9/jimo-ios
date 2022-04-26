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

struct MainAppView: View {

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @StateObject var viewModel = ViewModel()
    
    let currentUser: PublicUser
    
    var body: some View {
        UITabView(selection: viewModel.selectionIndex) {
            MapTab()
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .environmentObject(deepLinkManager)
                .tabItem("Map", image: UIImage(named: "mapIcon"))
            
            Feed(onCreatePostTap: { viewModel.selection = .create })
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .tabItem(
                    "Feed",
                    image: UIImage(named: "feedIcon"),
                    badgeValue: appState.unreadNotifications > 0 ? String(appState.unreadNotifications) : nil
                )
            
            Text("").tabItem("Save", image: UIImage(named: "postIcon"))
            
            Search()
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .tabItem("Discover", image: UIImage(named: "searchIcon"))
            
            ProfileTab(currentUser: currentUser)
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .tabItem("Profile", image: UIImage(named: "profileIcon"))
        }
        .sheet(isPresented: $viewModel.createPostPresented) {
            CreatePost(presented: $viewModel.createPostPresented)
                .trackSheet(.createPostSheet, screenAfterDismiss: { viewModel.currentTab })
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
        .onChange(of: deepLinkManager.presentableEntity) { item in
            if item != .none {
                viewModel.createPostPresented = false
                viewModel.selection = .map
            }
        }
    }
}

extension MainAppView {
    class ViewModel: ObservableObject {
        let newPostTag: Tab = .create
        
        @Published var createPostPresented: Bool = false
        @Published var selection: Tab {
            didSet {
                if selection == newPostTag {
                    selection = oldValue
                    createPostPresented = true
                }
            }
        }
        
        var selectionIndex: Binding<Int> {
            Binding<Int>(
                get: { self.selection.rawValue },
                set: { self.selection = Tab(rawValue: $0)! }
            )
        }
        
        var currentTab: Screen {
            switch selection {
            case .map:
                return .mapTab
            case .feed:
                return .feedTab
            case .create: /// Should never actually be here since create is a sheet and not a tab
                return .createPostSheet
            case .search:
                return .searchTab
            case .profile:
                return .profileTab
            }
        }
        
        init() {
            self.selection = Tab.map
        }
    }
}
