//
//  NavDestination.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/20/23.
//

import SwiftUI

enum NavDestination: Hashable {

    // Authentication
    case enterPhoneNumber
    case verifyPhoneNumber
    case emailLogin

    // Onboarding
    case cityOnboarding(city: String)

    // Main screens
    case profile(user: PublicUser)
    case post(post: Post, showSaveButton: Bool = false, highlightedComment: Comment? = nil)
    case notificationFeed

    // Map
    case liteMapView(post: Post)

    // Profile
    case followers(username: String)
    case following(username: String)

    // Settings
    case settings
    case editProfile
    case feedback
    case editPreferences

    // Deep linking
    case deepLink(entity: DeepLinkEntity)

    @ViewBuilder var view: some View {
        switch self {
        case .enterPhoneNumber:
            EnterPhoneNumber()
        case .verifyPhoneNumber:
            VerifyPhoneNumber(onVerify: {})
        case .emailLogin:
            EmailLogin()
        case .cityOnboarding(let city):
            CityPlaces(city: city)
        case .liteMapView(let post):
            LiteMapView(post: post)
        case .profile(let user):
            ProfileScreen(initialUser: user)
        case .post(let post, let showSave, let comment):
            ViewPost(initialPost: post, highlightedComment: comment, showSaveButton: showSave)
        case .notificationFeed:
            NotificationFeed()
        case .settings:
            Settings()
        case .editProfile:
            EditProfile()
        case .editPreferences:
            EditPreferences()
        case .feedback:
            Feedback()
        case .followers(let username):
            FollowFeed(navTitle: "Followers", type: .followers, username: username)
        case .following(let username):
            FollowFeed(navTitle: "Following", type: .following, username: username)
        case .deepLink(let entity):
            entity.view()
        }
    }
}
