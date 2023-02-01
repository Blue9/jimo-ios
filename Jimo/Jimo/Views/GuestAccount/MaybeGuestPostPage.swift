//
//  MaybeGuestPostPage.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/1/23.
//

import SwiftUI

struct MaybeGuestPostPage: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    var post: Post

    var showSignUpAlert: (SignUpTapSource) -> Void

    var body: some View {
        if appState.currentUser.isAnonymous {
            PostPage(post: post)
                .disabled(true)
                .onTapGesture {
                    showSignUpAlert(.placeDetailsViewPost)
                }
        } else {
            PostPage(post: post)
        }
    }
}
