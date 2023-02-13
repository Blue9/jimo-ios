//
//  MapType+image.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/31/23.
//

import SwiftUI

extension MapType {
    var buttonName: String {
        switch self {
        case .saved: return "Saved"
        case .me: return "My Posts"
        case .following: return "Following"
        case .community: return "Everyone"
        case .custom: return "Custom"
        }
    }

    var systemImage: String? {
        switch self {
        case .following: return "person.2.circle.fill"
        case .saved: return "bookmark.circle.fill"
        case .custom: return "ellipsis.circle.fill"
        default: return nil
        }
    }
}
