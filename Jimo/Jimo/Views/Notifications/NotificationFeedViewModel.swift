//
//  NotificationFeedViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/26/22.
//

import SwiftUI
import Combine

class NotificationFeedViewModel: ObservableObject {
    @Published var feedItems: [NotificationItem] = []
    @Published var loading = false
    @Published var shouldRequestNotificationPermissions = false

    private var cancellable: Cancellable?
    private var cursor: String?

    init() {
        PermissionManager.shared.getNotificationAuthStatus { status in
            DispatchQueue.main.async {
                self.shouldRequestNotificationPermissions = status != .authorized
            }
        }
    }

    func onAppear(appState: AppState, viewState: GlobalViewState) {
        self.refreshFeed(appState: appState, viewState: viewState)
    }

    func refreshFeed(appState: AppState, viewState: GlobalViewState, onFinish: OnFinish? = nil) {
        print("refreshing feed")
        cursor = nil
        loading = true
        cancellable = appState.getNotificationsFeed(token: nil)
            .sink(receiveCompletion: { [weak self] completion in
                self?.loading = false
                onFinish?()
                if case let .failure(error) = completion {
                    print("Error while load notification feed.", error)
                    viewState.setError("Could not load activity feed.")
                }
            }, receiveValue: { [weak self] response in
                self?.feedItems = response.notifications.filter { item in item.type != .unknown }
                self?.cursor = response.cursor
            })
    }

    func loadMoreNotifications(appState: AppState, viewState: GlobalViewState) {
        guard cursor != nil else {
            return
        }
        guard !loading else {
            return
        }
        loading = true
        print("Loading more notifications")
        cancellable = appState.getNotificationsFeed(token: cursor)
            .sink(receiveCompletion: { [weak self] completion in
                self?.loading = false
                if case let .failure(error) = completion {
                    print("Error while load more notifications.", error)
                    viewState.setError("Could not load more items.")
                }
            }, receiveValue: { [weak self] response in
                self?.feedItems.append(contentsOf: response.notifications.filter { item in item.type != .unknown })
                self?.cursor = response.cursor
            })
    }
}
