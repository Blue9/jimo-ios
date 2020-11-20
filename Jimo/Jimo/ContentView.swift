//
//  ContentView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI

struct ContentView: View {
    let viewModel = RemoteVM()

    var body: some View {
        TabView {
            Text("Home")
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            MapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            CreatePost()
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("New")
                }
            Search()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            Profile(profileVM: ProfileVM(appVM: viewModel, username: "gautam"))
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
