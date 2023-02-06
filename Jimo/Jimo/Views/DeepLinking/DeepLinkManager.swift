//
//  DeepLinkManager.swift
//  Jimo
//
//  Created by Xilin Liu on 4/20/22.
//

import SwiftUI

class DeepLinkManager: ObservableObject {
    @Published var presentableEntity: DeepLinkEntity?
}

/// What type of detail page we want to open based on the deeplink URL
enum DeepLinkEntity: Identifiable, NavigationDestinationEnum {
    case profile(String), post(PostId), loadedPost(Post)

    @ViewBuilder
    func view() -> some View {
        switch self {
        case .profile(let username):
            DeepLinkProfileLoadingScreen(username: username).id(username)
        case .post(let postId):
            DeepLinkViewPost(postId: postId)
        case .loadedPost(let post):
            ViewPost(initialPost: post)
        }
    }

    var id: String {
        switch self {
        case .profile(let username):
            return "profile-\(username)"
        case .post(let postId):
            return "postId-\(postId)"
        case .loadedPost(let post):
            return "post-\(post.postId)"
        }
    }
}

extension URL {
    private struct Constants {
        static let deeplinkHost = "go.jimoapp.com"

        static let profileDeeplinkPath = "/view-profile"
        static let profileQueryParam = "username"

        static let postDeeplinkPath = "/view-post"
        static let postQueryParam = "id"
    }

    /// checks whether URL is a deeplink, prefixed by our custom app scheme
    var isDeepLink: Bool { host == Constants.deeplinkHost }

    /// Decodes the entity type and entity Id from the deeplink
    /// e.g. `https://go.jimoapp.com/view-profile?username=<username>`
    var entityType: DeepLinkEntity? {
        guard isDeepLink,
              let urlComponents = URLComponents(string: absoluteString)
        else { return .none }

        switch urlComponents.path {
        case Constants.profileDeeplinkPath:
            guard let username = urlComponents.queryItems?.first(where: { $0.name == Constants.profileQueryParam })?.value
            else { return .none }
            return .profile(username)
        case Constants.postDeeplinkPath:
            guard let postUuid = urlComponents.queryItems?.first(where: { $0.name == Constants.postQueryParam })?.value
            else { return .none }
            return .post(postUuid)
        default: return .none
        }
    }
}
