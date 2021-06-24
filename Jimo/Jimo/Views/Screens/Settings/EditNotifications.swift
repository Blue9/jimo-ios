//
//  EditNotifications.swift
//  Jimo
//
//  Created by Gautam Mekkat on 6/4/21.
//

import SwiftUI

struct EditNotifications: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Toggle(isOn: $settingsViewModel.followNotifications) {
                VStack(alignment: .leading) {
                    Text("Followers")
                    
                    Text("Get notified when someone follows you")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            Toggle(isOn: $settingsViewModel.postLikedNotifications) {
                VStack(alignment: .leading) {
                    Text("Post likes")
                    
                    Text("Get notified when someone likes your post")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            Toggle(isOn: $settingsViewModel.commentNotifications) {
                VStack(alignment: .leading) {
                    Text("Comments")
                    
                    Text("Get notified when someone comments on your post")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            Toggle(isOn: $settingsViewModel.commentLikedNotifications) {
                VStack(alignment: .leading) {
                    Text("Comment likes")
                    
                    Text("Get notified when someone likes your comment")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            Button(action: {
                settingsViewModel.updatePreferences(appState: appState, viewState: globalViewState)
            }) {
                Text("Save preferences").foregroundColor(.blue)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavTitle("Notification settings")
            }
        }
    }
}

