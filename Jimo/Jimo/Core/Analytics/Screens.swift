//
//  Screens.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/29/22.
//

import Foundation

enum Screen: String {
    // Signed out
    case landing
    case enterPhoneNumber
    case enterVerificationCode
    case createProfile
    case onboarding // TODO: Split into individual onboarding screens, fine for now
    case guestLocationOnboarding

    // Authenticated
    case mapTab
    case feedTab
    case forYouFeed
    case createPostSheet
    case searchTab
    case profileTab
    case savedPosts

    case searchUsers

    // Other views
    case enterLocationView

    case postView
    case profileView

    case settings
    case inviteContacts
    case notificationFeed

    case unknown
}
