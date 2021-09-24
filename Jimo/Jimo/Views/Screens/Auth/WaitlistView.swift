//
//  WaitlistView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/3/21.
//

import SwiftUI
import Combine

struct WaitlistView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var waitlistStatus: UserWaitlistStatus? = nil
    @State private var loading = true
    @State private var showError = false
    @State private var errorMessage = "Failed to check invite status"
    
    @State private var waitlistCancellable: Cancellable? = nil
    
    func checkInviteStatus() {
        self.loading = true
        print("Checking waitlist status")
        waitlistCancellable = appState.getWaitlistStatus()
            .sink(receiveCompletion: { completion in
                self.loading = false
                if case let .failure(error) = completion {
                    print(error)
                    showError = true
                    waitlistStatus = nil
                }
            }, receiveValue: { status in
                self.waitlistStatus = status
            })
    }
    
    func joinWaitlist() {
        self.loading = true
        print("Joining waitlist")
        waitlistCancellable = appState.joinWaitlist()
            .sink(receiveCompletion: { completion in
                self.loading = false
                if case let .failure(error) = completion {
                    print(error)
                    showError = true
                    waitlistStatus = nil
                }
            }, receiveValue: { status in
                self.waitlistStatus = status
            })
    }
    
    var body: some View {
        ZStack {
            VStack {
                if loading {
                    ProgressView()
                }
                else if let waitlistStatus = waitlistStatus {
                    if waitlistStatus.invited {
                        Text("You're invited, create your profile")
                            .font(.system(size: 20))
                            .padding(.bottom, 20)
                        
                        NavigationLink(destination: CreateProfileView()) {
                            LargeButton("Let's go")
                                .padding(.horizontal, 40)
                        }
                    } else if waitlistStatus.waitlisted {
                        Text("You're on the waitlist! Stay tuned!")
                            .font(.system(size: 20))
                            .padding(.bottom, 20)
                        
                        Button(action: self.checkInviteStatus) {
                            LargeButton("Refresh status", fontSize: 20)
                                .padding(.horizontal, 40)
                        }
                        
                    } else {
                        Text("Tap below to join the waitlist")
                            .font(.system(size: 24))
                            .padding(.bottom, 20)
                        
                        Button(action: self.joinWaitlist) {
                            LargeButton("Join")
                                .padding(.horizontal, 40)
                        }
                    }
                } else {
                    Image(systemName: "arrow.clockwise")
                        .onTapGesture {
                            self.checkInviteStatus()
                        }
                }
            }
            
            VStack() {
                HStack {
                    Button("Refresh") {
                        self.checkInviteStatus()
                    }
                    .padding(20)
                    Spacer()
                    Button("Sign out") {
                        self.appState.signOut()
                    }
                    .padding(20)
                }
                Spacer()
            }
        }
        .onAppear {
            self.checkInviteStatus()
        }
        .background(Color(.sRGB, red: 0.95, green: 0.95, blue: 0.95, opacity: 1).edgesIgnoringSafeArea(.all))
        .popup(isPresented: $showError, type: .toast, autohideIn: 2) {
            Toast(text: errorMessage, type: .error)
        }
        .environment(\.font, .system(size: 18))
    }
}

struct WaitlistView_Previews: PreviewProvider {
    static var previews: some View {
        WaitlistView()
            .environmentObject(AppState(apiClient: APIClient()))
            .environmentObject(GlobalViewState())
    }
}
