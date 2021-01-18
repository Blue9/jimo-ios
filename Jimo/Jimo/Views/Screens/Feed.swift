//
//  Feed.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI
import Combine


class FeedViewState: ObservableObject {
    var appState: AppState
    var cancellable: Cancellable? = nil
    @Published var initialized = false
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func refreshFeed() {
        cancellable = appState.refreshFeed()
            .sink(receiveCompletion: { completion in
                if !self.initialized {
                    self.initialized = true
                }
                if case let .failure(error) = completion {
                    // TODO handle error
                    print("Error when refreshing feed", error)
                }
                self.scrollViewRefresh = false
            }, receiveValue: {})
    }
    
    @Published var scrollViewRefresh = false {
        didSet {
            if oldValue == false && scrollViewRefresh == true {
                print("Refreshing")
                refreshFeed()
            }
        }
    }
}

struct FeedBody: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var feedModel: FeedModel
    @ObservedObject var feedState: FeedViewState
    
    var body: some View {
        if !feedState.initialized {
            ProgressView()
                .onAppear {
                    feedState.refreshFeed()
                }
        } else {
            RefreshableScrollView(refreshing: $feedState.scrollViewRefresh) {
                ForEach(feedModel.currentFeed, id: \.self) { postId in
                    FeedItem(allPosts: appState.allPosts, feedItemVM: FeedItemVM(appState: appState, postId: postId))
                }
                Text("You've reached the end!")
            }
        }
    }
}

struct Feed: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            FeedBody(feedModel: appState.feedModel, feedState: FeedViewState(appState: appState))
                //.navigationTitle("Feed")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        NavTitle("Feed")
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct Feed_Previews: PreviewProvider {
    static let api = APIClient()
    static var previews: some View {
        Feed()
            .environmentObject(api)
            .environmentObject(AppState(apiClient: api))
    }
}
