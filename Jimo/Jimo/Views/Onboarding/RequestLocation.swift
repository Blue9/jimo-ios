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
            title: "Jimo works best with your location enabled",
            imageName: "location-icon",
            caption: "View your location on the Jimo map."
        )
    }
}
