//
//  DeepLinkOpenable.swift
//  Jimo
//
//  Created by Xilin Liu on 3/19/22.
//

import SwiftUI
import Foundation

extension URL {
    private struct Constants {
        static let DEEPLINK_HOST = "go.jimoapp.com"

        static let PROFILE_DEEPLINK_PATH = "view-profile"
        static let PROFILE_QUERY_PARAMETER = "username"

        static let POST_DEEPLINK_PATH = "view-post"
        static let POST_QUERY_PARAMETER = "id"
    }

    /// checks whether URL is a deeplink, prefixed by our custom app scheme
    var isDeepLink: Bool { host == Constants.DEEPLINK_HOST }

    /// Decodes the entity type and entity Id from the deeplink
    /// e.g. `https://go.jimoapp.com/view-profile?username=<username>`
    var entityType: DeepLinkEntity {
        guard isDeepLink,
              let urlComponents = URLComponents(string: absoluteString)
        else { return .none }

        switch urlComponents.path {
        case Constants.PROFILE_DEEPLINK_PATH:
            guard let username = urlComponents.queryItems?.first(where: { $0.name == Constants.PROFILE_QUERY_PARAMETER })?.value
            else { return .none }
            return .profile(username)
        case Constants.POST_DEEPLINK_PATH:
            guard let postUuid = urlComponents.queryItems?.first(where: { $0.name == Constants.POST_QUERY_PARAMETER })?.value
            else { return .none }
            return .post(postUuid)
        default: return .none
        }
    }
}

/// What type of detail page we want to open based on the deeplink URL
enum DeepLinkEntity {
    case profile(String), post(String), none
}

protocol DeepLinkOpenable: View {
    /// Handles opening a page, loaded with the ID
    /// Currently supports `Profile` or `Post` loading via deep link, each with an entity ID
    /// Then we make a request to backend to fetch the detail page for the entity and present to screen
    func openDetailPage(for entityType: DeepLinkEntity)
}
