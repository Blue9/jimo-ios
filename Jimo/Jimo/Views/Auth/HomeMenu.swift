//
//  HomeMenu.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/3/21.
//

import Combine
import SwiftUI
import FirebaseRemoteConfig

struct HomeMenu: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @StateObject var viewModel = ViewModel()
    @State private var currentWallpaperIndex = 0

    let height = UIScreen.main.bounds.height

    let wallpapers = [
        "wallpaper.nyc",
        "wallpaper.chicago",
        "wallpaper.london",
        "wallpaper.la",
        "wallpaper.tokyo",
        "wallpaper.madrid",
        "wallpaper.paris"
    ].shuffled()
    let wallpaperTimer = Timer.publish(every: 6, on: .main, in: .common).autoconnect()

    var body: some View {
        Navigator {
            mainBody.navigationBarHidden(true)
        }
    }

    var mainBody: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Image("logo")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color("foreground"))
                    .scaledToFit()
                    .frame(width: 175)
                Text("The social maps platform.")
                    .bold()
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16))
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
            .contentShape(Rectangle())
            .background(
                Color("background")
                    .ignoresSafeArea()
                    .mask(
                        LinearGradient(
                            colors: [
                                Color("background").opacity(0.8),
                                Color("background").opacity(0.7),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ).ignoresSafeArea()
                    )
            )
            .scaledToFit()
            Spacer()
            VStack(spacing: 5) {
                NavigationLink {
                    EnterPhoneNumber(onVerify: {})
                } label: {
                    LargeButton("Sign Up")
                }
                .buttonStyle(RaisedButtonStyle())
                .padding(.vertical, 8)

                HStack(spacing: 10) {
                    VStack { Divider().frame(maxWidth: 100) }
                    Text("OR").opacity(0.5)
                        .padding(.vertical, 8)
                    VStack { Divider().frame(maxWidth: 100) }
                }

                NavigationLink {
                    EnterPhoneNumber(onVerify: {})
                } label: {
                    Text("Sign in to an existing account")
                        .font(.system(size: 16))
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding(.bottom, 8)
                        .contentShape(Rectangle())
                        .foregroundColor(Color("foreground"))
                }

                Divider().frame(maxWidth: 200)

                Button {
                    Analytics.track(.signInAnonymous)
                    viewModel.signInAnonymously(appState: appState, viewState: viewState)
                } label: {
                    Text("Explore Jimo first")
                        .font(.system(size: 16))
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .foregroundColor(Color("foreground"))
                }
            }
            .padding(.horizontal, 50)
            .padding(.top, 60)
            .contentShape(Rectangle())
            .background(
                Color("background")
                    .ignoresSafeArea()
                    .mask(
                        LinearGradient(
                            colors: [
                                Color("background").opacity(0.8),
                                Color("background").opacity(0.8),
                                Color("background").opacity(0.7),
                                Color.clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        ).ignoresSafeArea()
                    )
            )
            .ignoresSafeArea()
        }
        .frame(maxHeight: .infinity)
        .background(
            Image(wallpapers[currentWallpaperIndex])
                .resizable()
                .scaledToFill()
                .frame(height: UIScreen.main.bounds.height)
                .ignoresSafeArea()
        )
        .onReceive(wallpaperTimer) { _ in
            withAnimation(.linear(duration: 1)) {
                currentWallpaperIndex = currentWallpaperIndex < wallpapers.count - 1 ? currentWallpaperIndex + 1 : 0
            }
        }
        .trackScreen(.landing)
    }
}

extension HomeMenu {
    @MainActor
    class ViewModel: ObservableObject {
        var cancelBag: Set<AnyCancellable> = .init()
        var signingIn = false

        func signInAnonymously(appState: AppState, viewState: GlobalViewState) {
            guard !signingIn else {
                return
            }
            signingIn = true
            appState.signInAnonymously()
                .sink { [weak self] completion in
                    if case let .failure(error) = completion {
                        viewState.setError("Cannot continue at this time (\(error.localizedDescription))")
                    }
                    self?.signingIn = false
                } receiveValue: { _ in
                    // pass
                }.store(in: &cancelBag)
        }
    }
}
