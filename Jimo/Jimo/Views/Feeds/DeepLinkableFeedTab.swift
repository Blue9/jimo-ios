//
//  DeepLinkableFeedTab.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/13/23.
//

import SwiftUI

struct DeepLinkableFeedTab: View {
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @ObservedObject var notificationsModel: NotificationBadgeModel
    @State private var isDeepLinkPresented = false

    var onCreatePostTap: () -> Void

    var body: some View {
        Navigator {
            FeedTabBody(
                notificationsModel: notificationsModel,
                onCreatePostTap: { globalViewState.createPostPresented = true }
            )
            // Workaround for iOS 15 vs 16 navigation discrepancies
            // Previously was simply `.navigation(destination: $deepLinkManager.presentableEntity)`.
            // For some reason the deep link opens fine when running through Xcode
            // but it doesn't work on its own. I think this is because presentableEntity is non-nil
            // by the time this view is built, so the navigation destination's `isPresented` is already true
            // and SwiftUI doesn't properly open. So I use a separate variable that's initially false and
            // set it to true after the view has loaded
            .navDestination(
                isPresented: Binding(
                    get: { isDeepLinkPresented },
                    set: { presented in
                        isDeepLinkPresented = presented
                        if !presented {
                            deepLinkManager.presentableEntity = nil
                        }
                    }
                )
            ) {
                if let entity = deepLinkManager.presentableEntity {
                    entity.view().id(entity.hashValue)
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                isDeepLinkPresented = deepLinkManager.presentableEntity != nil
            }
            .onChange(of: deepLinkManager.presentableEntity) { _ in
                isDeepLinkPresented = deepLinkManager.presentableEntity != nil
            }
        }
    }
}
