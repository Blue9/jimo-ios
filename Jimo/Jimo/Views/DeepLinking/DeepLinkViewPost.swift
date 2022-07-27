//
//  DeepLinkViewPost.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/26/22.
//

import SwiftUI
import Combine

struct DeepLinkViewPost: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @StateObject var viewModel = ViewModel()
    
    let postId: PostId
    
    var body: some View {
        Group {
            switch viewModel.loadStatus {
            case .loading:
                ProgressView()
                    .onAppear {
                        viewModel.load(postId, appState: appState, viewState: viewState)
                    }
            case .failed:
                ProgressView()
                    .onAppear {
                        presentationMode.wrappedValue.dismiss()
                    }
            case .success(let post):
                ViewPost(initialPost: post)
            }
        }
        .background(Color("background"))
    }
}

extension DeepLinkViewPost {
    class ViewModel: ObservableObject {
        @Published var loadStatus: Status = .loading
        
        var cancelBag: Set<AnyCancellable> = .init()
        
        func load(_ postId: PostId, appState: AppState, viewState: GlobalViewState) {
            self.loadStatus = .loading
            appState.getPost(postId)
                .sink { [weak self] completion in
                    if case let .failure(error) = completion {
                        print("Error when loading post", error)
                        viewState.setError("Post not found")
                        self?.loadStatus = .failed
                    }
                } receiveValue: { [weak self] post in
                    self?.loadStatus = .success(post)
                }.store(in: &cancelBag)
        }
        
        enum Status: Equatable {
            case loading, success(Post), failed
        }
    }
}
