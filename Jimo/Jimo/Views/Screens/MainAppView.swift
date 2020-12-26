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
            print("Selecting " + String(selection) + " old " + String(oldValue))
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
    @EnvironmentObject var model: AppModel
    
    let profileVM: ProfileVM
    let feedModel: FeedModel
    
    var body: some View {
        TabView(selection: $tabBar.selection) {
            Feed(feedModel: feedModel)
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
        .sheet(isPresented: $tabBar.newPostSelected) {
            return CreatePost(presented: $tabBar.newPostSelected)
                .preferredColorScheme(.light)
        }
    }
}

struct MainAppView_Previews: PreviewProvider {
    static let model = AppModel()
    static var previews: some View {
        MainAppView(profileVM: ProfileVM(model: model, username: "gautam"),
                    feedModel: FeedModel(model: model))
    }
}
