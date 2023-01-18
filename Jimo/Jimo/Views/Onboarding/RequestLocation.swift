//
//  RequestLocation.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/28/22.
//

import SwiftUI

struct RequestLocation: View {
    var onCompleteRequest: () -> Void

    var body: some View {
        RequestPermission(
            onCompleteRequest: onCompleteRequest,
            action: PermissionManager.shared.requestLocation,
            title: "Allowing location helps you find nearby recs",
            imageName: "location-icon",
            caption: "e.g., You are close to Alex's recommendation",
            privacyCaption: "We do not store your location on our servers."
        )
    }
}
