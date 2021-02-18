//
//  Feed.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI
import Combine


class FeedViewState: ObservableObject {
    let appState: AppState
    let globalViewState: GlobalViewState
    
    var cancellable: Cancellable? = nil
    @Published var initialized = false
    
    init(appState: AppState, globalViewState: GlobalViewState) {
        self.appState = appState
        self.globalViewState = globalViewState
    }
    
    func refreshFeed() {
        cancellable = appState.refreshFeed()
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else {
                    return
                }
                if !self.initialized {
                    self.initialized = true
                }
                if case let .failure(error) = completion {
                    print("Error when refreshing feed", error)
                    self.globalViewState.setError("Could not refresh feed")
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
    @EnvironmentObject var viewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    @ObservedObject var feedModel: FeedModel
    @StateObject var feedState: FeedViewState
    
    var body: some View {
        Group {
            if !feedState.initialized {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        feedState.refreshFeed()
                    }
            } else {
                RefreshableScrollView(refreshing: $feedState.scrollViewRefresh) {
                    ForEach(feedModel.currentFeed, id: \.self) { postId in
                        FeedItem(feedItemVM: FeedItemVM(appState: appState, viewState: viewState, postId: postId))
                    }
                    Text("You've reached the end!")
                        .padding(.top, 40)
                }
            }
        }
        .background(backgroundColor)
    }
}

struct Feed: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor

    var body: some View {
        NavigationView {
            FeedBody(feedModel: appState.feedModel, feedState: FeedViewState(appState: appState, globalViewState: globalViewState))
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarColor(UIColor(backgroundColor))
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        NavTitle("Feed")
                    }
                }
        }
    }
}

struct Feed_Previews: PreviewProvider {
    static let api = APIClient()
    static var previews: some View {
        Feed()
            .environmentObject(AppState(apiClient: api))
            .environmentObject(GlobalViewState())
    }
}
