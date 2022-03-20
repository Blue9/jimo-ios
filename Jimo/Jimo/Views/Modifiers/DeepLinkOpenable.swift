//
//  DeepLinkOpenable.swift
//  Jimo
//
//  Created by Xilin Liu on 3/19/22.
//

import SwiftUI
import Foundation

extension URL {
    /// checks whether URL is a deeplink, prefixed by our custom app scheme
    var isDeepLink: Bool { scheme == "jimoapp" }

    /// Decodes the entity type and entity Id from the deeplink
    /// e.g. `jimoapp://profile/1`
    var entityType: DeepLinkEntity {
        guard
            isDeepLink,
            let entityId = Int(path.dropFirst(1))
        else { return .none }

        switch host {
        case "profile": return .profile(entityId)
        case "post": return .post(entityId)
        default: return .none
        }
    }
}

/// What type of detail page we want to open based on the deeplink URL
enum DeepLinkEntity {
    case profile(Int), post(Int), none
}

protocol DeepLinkOpenable: View {
    /// Handles opening a page, loaded with the ID
    /// Currently supports `Profile` or `Post` loading via deep link, each with an entity ID
    /// Then we make a request to backend to fetch the detail page for the entity and present to screen
    func openDetailPage(for entityType: DeepLinkEntity)
}
