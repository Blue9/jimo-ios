//
//  MainAppView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI

enum Tab: Int {
    case feed = 0, map = 1, create = 2, search = 3, profile = 4
}

struct MainAppView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @ObservedObject var notificationsModel: NotificationBadgeModel
    @StateObject private var viewModel = ViewModel()
    @State private var signUpAlert: SignUpAlert = .init(isPresented: false, source: .none)
    @State private var showWelcomeAlert = false
    @AppStorage("firstOpen") var firstOpen = true
    let currentUser: PublicUser?

    var selectionIndex: Binding<Int> {
        Binding<Int>(
            get: { viewModel.selection.rawValue },
            set: {
                if $0 == Tab.create.rawValue {
                    globalViewState.createPostPresented = true
                } else if $0 == Tab.search.rawValue  && appState.currentUser.isAnonymous {
                    signUpAlert = .init(isPresented: true, source: .searchUsers)
                } else {
                    viewModel.selection = Tab(rawValue: $0)!
                }
            }
        )
    }

    var body: some View {
        ZStack {
            mainBody
        }.alert("Account required", isPresented: $signUpAlert.isPresented) {
            Button("Later", action: {
                signUpAlert = .init(isPresented: false, source: .none)
            })

            Button("Sign up", action: {
                globalViewState.showSignUpPage(signUpAlert.source)
            })
        } message: {
            Text(signUpAlert.source.signUpNudgeText ?? "Sign up for the full experience")
        }
        .onAppear {
            firstOpen = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showWelcomeAlert = firstOpen
                firstOpen = false
            }
        }
        .popup(isPresented: $showWelcomeAlert) {
            FirstOpenPopup(
                isPresented: $showWelcomeAlert,
                goToProfile: { viewModel.selection = .profile }
            )
        } customize: {
            $0
                .type(.floater(verticalPadding: 80))
                .position(.bottom)
                .closeOnTap(false)
                .backgroundColor(.black.opacity(0.4))
        }
    }

    var mainBody: some View {
        UITabView(selection: selectionIndex) {
            FeedTab(
                notificationsModel: notificationsModel,
                onCreatePostTap: { globalViewState.createPostPresented = true }
            )
            .environmentObject(appState)
            .environmentObject(globalViewState)
            .tabItem(
                "Feed",
                image: UIImage(named: "feedIcon"),
                badgeValue: notificationsModel.unreadNotifications > 0 ? String(notificationsModel.unreadNotifications) : nil
            )

            MapTab(
            )
            .environmentObject(appState)
            .environmentObject(globalViewState)
            .environmentObject(deepLinkManager)
            .tabItem("Map", image: UIImage(named: "mapIcon"))

            Text("")
                .tabItem("Create", image: UIImage(named: "postIcon"))

            SearchTab(
            )
            .environmentObject(appState)
            .environmentObject(globalViewState)
            .tabItem("Search", image: UIImage(named: "searchIcon"))

            ProfileTab(
                currentUser: currentUser
            )
            .environmentObject(appState)
            .environmentObject(globalViewState)
            .tabItem("Profile", image: UIImage(named: "profileIcon"))
        }
        .sheet(isPresented: $globalViewState.createPostPresented) {
            if appState.currentUser.isAnonymous {
                CreatePost(presented: $globalViewState.createPostPresented)
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
                    .environmentObject(deepLinkManager)
                    .disabled(true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        globalViewState.createPostPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                            signUpAlert = .init(isPresented: true, source: .createPost)
                        }
                    }
            } else {
                CreatePost(presented: $globalViewState.createPostPresented)
                    .trackSheet(.createPostSheet, screenAfterDismiss: { viewModel.currentTab })
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
                    .environmentObject(deepLinkManager)
            }
        }
        .accentColor(Color("foreground"))
        .onAppear {
            UITabBar.appearance().shadowImage = UIImage()
            UITabBar.appearance().backgroundImage = UIImage()
            UITabBar.appearance().barTintColor = UIColor(Color("background"))
            UITabBar.appearance().backgroundColor = UIColor(Color("background"))
        }
        .onChange(of: deepLinkManager.presentableEntity) { item in
            if item != .none {
                globalViewState.createPostPresented = false
                viewModel.selection = .map
            }
        }
    }
}

fileprivate extension MainAppView {
    class ViewModel: ObservableObject {
        @Published var selection: Tab = Tab.map

        var currentTab: Screen? {
            switch selection {
            case .feed:
                return .feedTab
            case .map:
                return .mapTab
            case .create:
                return nil // Special cased
            case .search:
                return .searchTab
            case .profile:
                return .profileTab
            }
        }
    }
}
