//
//  MainAppView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI

enum Tab: Int {
    case feed = 0, map = 1, profile = 2
}

struct MainAppView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @StateObject private var viewModel = ViewModel()
    @State private var signUpAlert: SignUpAlert = .init(isPresented: false, source: .none)
    let currentUser: PublicUser?

    var mainBody: some View {
        UITabView(selection: viewModel.selectionIndex) {
            FeedTab(onCreatePostTap: { viewModel.createPostPresented = true })
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .tabItem(
                    "",
                    image: UIImage(named: "feedIcon"),
                    badgeValue: appState.unreadNotifications > 0 ? String(appState.unreadNotifications) : nil
                )

            MapTab()
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .environmentObject(deepLinkManager)
                .tabItem("", image: UIImage(named: "mapIcon"))

            ProfileTab(currentUser: currentUser)
                .environmentObject(appState)
                .environmentObject(globalViewState)
                .tabItem("", image: UIImage(named: "profileIcon"))
        }
        .sheet(isPresented: $viewModel.createPostPresented) {
            if appState.currentUser.isAnonymous {
                CreatePost(presented: $viewModel.createPostPresented)
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
                    .disabled(true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.createPostPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                            signUpAlert = .init(isPresented: true, source: .createPost)
                        }
                    }
            } else {
                CreatePost(presented: $viewModel.createPostPresented)
                    .trackSheet(.createPostSheet, screenAfterDismiss: { viewModel.currentTab })
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
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
                viewModel.createPostPresented = false
                viewModel.selection = .map
            }
        }
    }

    @ViewBuilder
    var newPostButton: some View {
        ZStack {
            Circle()
                .fill()
                .foregroundColor(.white)
                .frame(width: 55, height: 55)
            Button(action: {
                viewModel.createPostPresented = true
            }) {
                ZStack {
                    Circle()
                        .fill()
                        .foregroundColor(.blue)
                        .frame(width: 55, height: 55)
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 30))
                }
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            mainBody

            newPostButton
                .opacity(viewModel.selection == .map ? 1 : 0)
                .alert("Account required", isPresented: $signUpAlert.isPresented) {
                    Button("Later", action: {
                        signUpAlert = .init(isPresented: false, source: .none)
                    })

                    Button("Sign up", action: {
                        globalViewState.showSignUpPage(signUpAlert.source)
                    })
                } message: {
                    Text(signUpAlert.source.signUpNudgeText ?? "Sign up for the full experience")
                }
        }
    }
}

fileprivate extension MainAppView {
    class ViewModel: ObservableObject {
        @Published var createPostPresented: Bool = false
        @Published var selection: Tab = Tab.map

        var selectionIndex: Binding<Int> {
            Binding<Int>(
                get: { self.selection.rawValue },
                set: { self.selection = Tab(rawValue: $0)! }
            )
        }

        var currentTab: Screen {
            switch selection {
            case .feed:
                return .feedTab
            case .map:
                return .mapTab
            case .profile:
                return .profileTab
            }
        }
    }
}
