//
//  HomeMenu.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/3/21.
//

import Combine
import SwiftUI

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
                Text("Sign up to see recs\nfrom your friends.")
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
                .padding(.bottom, 8)
                .buttonStyle(RaisedButtonStyle())

                HStack(spacing: 10) {
                    VStack {
                        Divider()
                            .frame(maxWidth: 100)
                            .background(Color("foreground"))
                    }
                    Text("OR")
                        .font(.system(size: 16))
                        .foregroundColor(Color("foreground"))
                    VStack {
                        Divider()
                            .frame(maxWidth: 100)
                            .background(Color("foreground"))
                    }
                }

                NavigationLink {
                    EnterPhoneNumber(onVerify: {})
                } label: {
                    Group {
                        Text("Already have an account? ") + Text("Sign in").bold()
                    }
                    .font(.system(size: 16))
                    .minimumScaleFactor(0.8)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .foregroundColor(Color("foreground"))
                }

                Button {
                    Analytics.track(.homeMenuAnonymous)
                    viewModel.signInAnonymously(appState: appState, viewState: viewState)
                } label: {
                    Group {
                        Text("Continue without an account")
                    }
                    .font(.system(size: 16))
                    .minimumScaleFactor(0.8)
                    .frame(minWidth: 0, maxWidth: .infinity)
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
    class ViewModel: ObservableObject {
        var cancelBag: Set<AnyCancellable> = .init()

        func signInAnonymously(appState: AppState, viewState: GlobalViewState) {
            appState.signInAnonymously()
                .sink { completion in
                    if case let .failure(error) = completion {
                        viewState.setError("Cannot continue at this time (\(error.localizedDescription))")
                    }
                } receiveValue: { _ in
                    // pass
                }.store(in: &cancelBag)
        }
    }
}
