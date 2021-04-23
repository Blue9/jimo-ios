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
        self.selection = 0
        self.previousSelection = 0
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
            UIKitTabView(selectedIndex: $tabBar.selection) {
                UIKitTabView.Tab(
                    view: AnyView(Feed()
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)
                                    .environment(\.backgroundColor, backgroundColor)),
                    barItem: .init(title: "Home", image: UIImage(named: "feedIcon"), tag: 0)
                )
                
                UIKitTabView.Tab(
                    view: AnyView(MapTab(mapModel: appState.mapModel, localSettings: appState.localSettings, mapViewModel: mapVM)
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)
                                    .environment(\.backgroundColor, backgroundColor)),
                    barItem: .init(title: "Map", image: UIImage(named: "mapIcon"), tag: 1)
                )
                UIKitTabView.Tab(
                    view: AnyView(Text("")
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)
                                    .environment(\.backgroundColor, backgroundColor)),
                    barItem: .init(title: "New", image: UIImage(named: "postIcon"), tag: 2)
                )
                UIKitTabView.Tab(
                    view: AnyView(Search()
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)
                                    .environment(\.backgroundColor, backgroundColor)),
                    barItem: .init(title: "Search", image: UIImage(named: "searchIcon"), tag: 3)
                )
                UIKitTabView.Tab(
                    view: AnyView(ProfileTab(profileVM: profileVM)
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)
                                    .environment(\.backgroundColor, backgroundColor)),
                    barItem: .init(title: "Profile", image: UIImage(named: "profileIcon"), tag: 4)
                )
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
