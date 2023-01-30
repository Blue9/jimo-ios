//
//  ContentView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI
import FirebaseRemoteConfig

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.colorScheme) var colorScheme

    @StateObject var networkMonitor = NetworkConnectionMonitor()
    @StateObject var appVersionModel = AppVersionModel()

    var body: some View {
        VStack {
            if appVersionModel.isOutOfDate {
                RequireUpdateView()
            } else if case .doesNotExist = appState.firebaseSession {
                HomeMenu()
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
            } else if case .loading = appState.firebaseSession {
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .offset(y: -5)
            } else if case .loading = appState.currentUser {
                // Firebase user exists, loading user profile
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .offset(y: -5)
            } else if case .failed = appState.currentUser {
                // Firebase user exists, failed while loading user profile
                FailedToLoadView()
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
            } else if appState.me != nil {
                // Both exist
                LoggedInView(onboardingModel: appState.onboardingModel, currentUser: appState.me!)
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
                    .id(appState.me) // Force view reset when current user changes (i.e., when updating profile)
            } else if case .deactivated = appState.currentUser {
                DeactivatedProfileView()
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
            } else { // appState.currentUser == .empty
                // Firebase user exists, user profile does not exist
                CreateProfileView()
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .popup(isPresented: !$networkMonitor.connected, type: .toast, position: .bottom, autohideIn: nil, closeOnTap: true) {
            Toast(text: "No internet connection", type: .error)
        }
        .popup(isPresented: $globalViewState.showError, type: .toast, position: .bottom, autohideIn: 4, closeOnTap: true, closeOnTapOutside: false) {
            Toast(text: globalViewState.errorMessage, type: .error)
                .padding(.bottom, 50)
        }
        .popup(isPresented: $globalViewState.showWarning, type: .toast, position: .bottom, autohideIn: 2, closeOnTap: true, closeOnTapOutside: false) {
            Toast(text: globalViewState.warningMessage, type: .warning)
                .padding(.bottom, 50)
        }
        .popup(isPresented: $globalViewState.showSuccess, type: .toast, position: .bottom, autohideIn: 2, closeOnTap: true, closeOnTapOutside: false) {
            Toast(text: globalViewState.successMessage, type: .success)
                .padding(.bottom, 50)
        }
        .shareOverlay(globalViewState.shareAction, isPresented: $globalViewState.showShareOverlay)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            appVersionModel.refreshMinimumAppVersion()
            appState.listen()
            networkMonitor.listen()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            appVersionModel.refreshMinimumAppVersion()
        }
    }
}

private struct FailedToLoadView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Navigator {
            VStack {
                Spacer()
                Button("Could not connect. Tap to try again.") {
                    appState.refreshCurrentUser()
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text("Loading profile"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign out") {
                        appState.signOut()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private struct RequireUpdateView: View {
    var body: some View {
        VStack {
            Spacer()
            Image("icon")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
            HStack {
                Spacer()
                Text("A new version of Jimo is available.\nPlease update to keep things\nrunning smoothly.")
                    .multilineTextAlignment(.center)
                Spacer()
            }

            Button {
                // Go to app store
                Analytics.track(.updateAppVersionTapped)
                UIApplication.shared.open(URL(string: "itms-apps://itunes.apple.com/app/id1541360118?mt=8")!)
            } label: {
                Text("Update")
                    .padding(10)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            Spacer()
        }
    }
}

@MainActor
class AppVersionModel: ObservableObject {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    @Published var minimumAppVersion: String?

    var isOutOfDate: Bool {
        guard let min = minimumAppVersion, let current = appVersion else {
            return false
        }
        return min.compare(current, options: .numeric) == .orderedDescending
    }

    func refreshMinimumAppVersion() {
        Task {
            try await startFetching()
        }
    }

    private func startFetching() async throws {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3600
        #endif
        remoteConfig.configSettings = settings

        do {
            try await remoteConfig.fetchAndActivate()
            self.minimumAppVersion = remoteConfig.configValue(forKey: "minimumAppVersion").stringValue
        } catch let error {
            print("Error fetching remote config \(error.localizedDescription)")
        }
    }
}
