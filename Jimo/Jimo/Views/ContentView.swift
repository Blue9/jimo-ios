//
//  ContentView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI
import PopupView
import FirebaseRemoteConfig

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.colorScheme) var colorScheme

    @StateObject var networkMonitor = NetworkConnectionMonitor()
    @StateObject var appVersionModel = AppVersionModel()

    var body: some View {
        ZStack {
            if appVersionModel.isOutOfDate {
                RequireUpdateView()
            } else {
                switch appState.currentUser {
                case .loading:
                    Image("icon")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .offset(y: -5)
                        .id("loading")
                case let .user(user):
                    LoggedInView(onboardingModel: appState.onboardingModel, currentUser: user)
                        .id(user)
                case .anonymous:
                    UnauthedOnboarding()
                case .signedOut:
                    HomeMenu()
                case .failed:
                    FailedToLoadView()
                case .deactivated:
                    DeactivatedProfileView()
                case .phoneAuthed:
                    CreateProfileView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fullScreenCover(isPresented: $globalViewState.showSignUpPage) {
            FakeNavigator {
                EnterPhoneNumber()
                // TODO globalViewState.showSignUpPage = false on verify
                    .navigationTitle(Text("Sign up"))
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                globalViewState.showSignUpPage = false
                            } label: {
                                Image(systemName: "xmark").foregroundColor(Color("foreground"))
                            }
                        }
                    }
            }
        }
        .popup(isPresented: !$networkMonitor.connected) {
            Toast(text: "No internet connection", type: .error)
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .autohideIn(nil)
                .closeOnTap(true)
        }
        .popup(isPresented: $globalViewState.showError) {
            Toast(text: globalViewState.errorMessage, type: .error)
                .padding(.bottom, 50)
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .autohideIn(4)
                .closeOnTap(true)
                .closeOnTapOutside(false)
        }
        .popup(isPresented: $globalViewState.showWarning) {
            Toast(text: globalViewState.warningMessage, type: .warning)
                .padding(.bottom, 50)
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .autohideIn(2)
                .closeOnTap(true)
                .closeOnTapOutside(false)
        }
        .popup(isPresented: $globalViewState.showSuccess) {
            Toast(text: globalViewState.successMessage, type: .success)
                .padding(.bottom, 50)
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .autohideIn(2)
                .closeOnTap(true)
                .closeOnTapOutside(false)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            appVersionModel.refreshMinimumAppVersion()
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
        VStack {
            HStack {
                Spacer()
                Button("Sign out") {
                    appState.signOut()
                }
            }.padding()
            Spacer()
            Button("Could not connect. Tap to try again.") {
                appState.refreshCurrentUser()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        // RemoteConfig is initialized in AppState+RemoteConfig.swift
        self.minimumAppVersion = RemoteConfig.remoteConfig().configValue(forKey: "minimumAppVersion").stringValue
    }
}
