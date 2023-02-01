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

    let height = UIScreen.main.bounds.height

    var body: some View {
        Navigator {
            mainBody.navigationBarHidden(true)
        }
    }

    var mainBody: some View {
        VStack(spacing: 0) {
            Spacer().frame(maxHeight: height * 0.22)

            VStack(spacing: 0) {
                Image("logo")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color("foreground"))
                    .scaledToFit()
                    .frame(width: 175)
                Text("The social maps platform.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16))
            }
            .scaledToFit()

            Spacer().frame(maxHeight: height * 0.23)

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
            .padding(.bottom, 50)

            Spacer()
        }
        .padding(.horizontal, 50)
        .frame(maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
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
