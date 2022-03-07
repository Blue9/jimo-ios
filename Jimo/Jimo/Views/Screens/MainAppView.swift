//
//  MainAppView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI
import FirebaseAnalytics

enum Tab: Int {
<<<<<<< Updated upstream
    case feed = 0, map = 1, create = 2, search = 3, profile = 4
=======
    case map = 0, feed = 1, create = 2, search = 3, profile = 4
>>>>>>> Stashed changes
    
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
//            print(">>>*******************************")
//            print(">>> \(selection)")
//            print(">>> \(newPostTag.rawValue)")
//            print(">>> \(newPostSelected)")
//            print(">>>*******************************")

            if selection == newPostTag.rawValue {
                previousSelection = Tab(rawValue: oldValue)
                newPostSelected = true
<<<<<<< Updated upstream
                selection = oldValue
            } else if !newPostSelected {
                logTabSelection(tab: Tab(rawValue: selection)!)
=======
//                logCreatePostTab()
            } else if !newPostSelected {
                print(newPostSelected)
                logTabSelection(tab: Tab(rawValue: selection)!)
                

>>>>>>> Stashed changes
            }
        }
    }
    
    var previousSelection: Tab?
    
    
    init() {
<<<<<<< Updated upstream
        self.selection = Tab.feed.rawValue
        logTabSelection(tab: Tab.feed)
=======
        self.selection = Tab.map.rawValue
        logTabSelection(tab: Tab.map)

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
        print(">>tab", tab.string)
=======
        print(">>>tab", tab.string)
>>>>>>> Stashed changes
    }
    
    private func logCreatePostTab() {
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [AnalyticsParameterScreenName: "create", AnalyticsParameterScreenClass: "create"]
        )
<<<<<<< Updated upstream
        print(">>tab create")
=======
        print(">>>tab1 create")
>>>>>>> Stashed changes
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
                    view: AnyView(Feed(onCreatePostTap: { tabBar.selection = Tab.create.rawValue })
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)),
                    barItem: .init(title: nil, image: UIImage(named: "feedIcon"), tag: Tab.feed.rawValue)
                )
                
                UIKitTabView.Tab(
                    view: AnyView(MapTab()
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)),
                    barItem: .init(title: nil, image: UIImage(named: "mapIcon"), tag: Tab.map.rawValue)
                )
                UIKitTabView.Tab(
                    view: AnyView(Text("")
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)),
                    barItem: .init(title: nil, image: UIImage(named: "postIcon"), tag: Tab.create.rawValue)
                )
                UIKitTabView.Tab(
                    view: AnyView(Search()
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)),
                    barItem: .init(title: nil, image: UIImage(named: "searchIcon"), tag: Tab.search.rawValue)
                )
                UIKitTabView.Tab(
                    view: AnyView(ProfileTab(currentUser: currentUser)
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)),
                    barItem: .init(title: nil, image: UIImage(named: "profileIcon"), tag: Tab.profile.rawValue)
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
