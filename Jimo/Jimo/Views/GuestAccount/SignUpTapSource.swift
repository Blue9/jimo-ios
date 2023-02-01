//
//  SignUpTapSource.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/1/23.
//

enum SignUpTapSource: String {
    case none,
         feed,
         profile,
         filterSaves,
         filterMe,
         filterFriends,
         filterCommunity,
         placeDetailsNudge,
         placeDetailsRate,
         placeDetailsSave,
         placeDetailsViewPost,
         createPost,
         customUserFilter

    // Only set if the source displays a sign up nudge alert (feed and profile go directly to sign up page)
    var signUpNudgeText: String? {
        switch self {
        case .none: return nil
        case .feed: return nil
        case .profile: return nil
        case .filterSaves: return "Sign up to start saving places."
        case .filterMe: return "Sign up to start posting places."
        case .filterFriends: return "Sign up to follow and invite friends."
        case .filterCommunity: return "Sign up to view the community map."
        case .placeDetailsNudge: return nil
        case .placeDetailsRate: return "Sign up to start rating places."
        case .placeDetailsSave: return "Sign up to start saving places."
        case .placeDetailsViewPost: return "Sign up to interact with posts."
        case .createPost: return "Sign up to start rating places."
        case .customUserFilter: return nil
        }
    }

    var analyticsSourceParameter: String {
        self.rawValue
    }
}
