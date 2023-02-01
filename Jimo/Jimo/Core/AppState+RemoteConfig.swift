//
//  AppState+RemoteConfig.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/1/23.
//

import SwiftUI
import FirebaseRemoteConfig

extension AppState {
    func refreshRemoteConfig() {
        // Defaults are set in AppState.init
        Task {
            try await fetch()
        }
    }

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
