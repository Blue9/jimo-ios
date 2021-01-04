//
//  Feed.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI

class FeedViewState: ObservableObject {
    var postModel: PostModel
    
    init(postModel: PostModel) {
        self.postModel = postModel
    }
    
    @Published var scrollViewRefresh = false {
        didSet {
            if oldValue == false && scrollViewRefresh == true {
                print("Refreshing")
                postModel.refreshFeed(then: { error in
                    // TODO show error toast if error not nil
                    self.scrollViewRefresh = false
                })
            }
        }
    }
}

struct FeedBody: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var postModel: PostModel
    @ObservedObject var feedState: FeedViewState
    
    var body: some View {
        if postModel.feedState == .initializing {
            Text(postModel.feedState == .initializing ? "Init" : "Done")
            ProgressView()
                .onAppear {
                    postModel.refreshFeed(then: { error in })
                }
        } else {
            RefreshableScrollView(refreshing: $feedState.scrollViewRefresh) {
                ForEach(postModel.feed) { post in
                    FeedItem(post: post)
                }
                Text("You've reached the end!")
            }
        }
    }
}

struct Feed: View {
    @EnvironmentObject var postModel: PostModel

    var body: some View {
        NavigationView {
            FeedBody(feedState: FeedViewState(postModel: postModel))
                //.navigationTitle("Feed")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        NavTitle("Feed")
                    }
                }
        }
    }
}

struct Feed_Previews: PreviewProvider {
    static let model = AppModel()
    static var previews: some View {
        Feed().environmentObject(model).environmentObject(PostModel(model: model, state: .initializing))
    }
}
