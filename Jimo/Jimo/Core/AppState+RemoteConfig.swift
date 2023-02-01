//
//  AppState+RemoteConfig.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/1/23.
//

import SwiftUI
import FirebaseRemoteConfig

extension AppState {
    func initializeRemoteConfig() {
        RemoteConfig.remoteConfig().setDefaults([
            "locationPingInterval": 120.0 as NSObject
        ])
        self.refreshRemoteConfig()
    }

    func refreshRemoteConfig() {
        Task {
            try await fetch()
        }
    }

    @MainActor
    private func fetch() async throws {
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #endif
        RemoteConfig.remoteConfig().configSettings = settings
        do {
            try await RemoteConfig.remoteConfig().fetchAndActivate()
        } catch let error {
            print("Error fetching remote config \(error.localizedDescription)")
        }
    }
}
