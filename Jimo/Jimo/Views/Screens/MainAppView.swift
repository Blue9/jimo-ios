//
//  MainAppView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI

class TabBar: ObservableObject {
    let newPostTag = 2
    
    @Published var newPostSelected = false
    @Published var selection: Int {
        didSet {
            if selection == newPostTag {
                previousSelection = oldValue
                selection = oldValue
                newPostSelected = true
            }
        }
    }
    
    var previousSelection: Int
    
    init() {
        self.selection = 0
        self.previousSelection = 0
    }
    
    func reset() {
        selection = previousSelection
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
        ZStack {
            UIKitTabView(selectedIndex: $tabBar.selection) {
                UIKitTabView.Tab(
                    view: AnyView(Feed()
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)),
                    barItem: .init(title: nil, image: UIImage(named: "feedIcon"), tag: 0)
                )
                
                UIKitTabView.Tab(
                    view: AnyView(MapTab(localSettings: appState.localSettings)
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)),
                    barItem: .init(title: nil, image: UIImage(named: "mapIcon"), tag: 1)
                )
                UIKitTabView.Tab(
                    view: AnyView(Text("")
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)),
                    barItem: .init(title: nil, image: UIImage(named: "postIcon"), tag: 2)
                )
                UIKitTabView.Tab(
                    view: AnyView(Search()
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)),
                    barItem: .init(title: nil, image: UIImage(named: "searchIcon"), tag: 3)
                )
                UIKitTabView.Tab(
                    view: AnyView(ProfileTab(currentUser: currentUser)
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)),
                    barItem: .init(title: nil, image: UIImage(named: "profileIcon"), tag: 4)
                )
            }
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
