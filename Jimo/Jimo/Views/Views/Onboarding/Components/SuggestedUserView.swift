//
//  SuggestedUserView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/14/21.
//

import SwiftUI

struct SuggestedUserView<T: SuggestedUserStore>: View {
    @ObservedObject var userStore: T
    let user: PublicUser
    
    var profilePicture: URLImage {
        return URLImage(url: user.profilePictureUrl,
                        loading: Image(systemName: "person.crop.circle").resizable())
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                profilePicture
                    .foregroundColor(.gray)
                    .background(Color.white)
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(40)
                
                if userStore.selectedUsernames.contains(user.username) {
                    Image("selectedContact")
                        .resizable()
                        .frame(width: 26, height: 26)
                        .shadow(radius: 5)
                }
            }
            
            Text(user.firstName + " " + user.lastName)
                .font(.system(size: 12))
        }
        .onTapGesture {
            userStore.toggleSelected(for: user.username)
        }
    }
}
