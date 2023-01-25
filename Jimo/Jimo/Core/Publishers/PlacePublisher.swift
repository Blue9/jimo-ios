//
//  PlacePublisher.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/24/23.
//

import Foundation

struct PlaceSavePayload: Codable, Equatable {
    var placeId: PlaceId
    var save: SavedPlace?
    var createPlaceRequest: MaybeCreatePlaceRequest?
}

class PlacePublisher {
    let notificationCenter = NotificationCenter.default

    static let placeSaved = Notification.Name("place:saved")

    func placeSaved(_ payload: PlaceSavePayload) {
        notificationCenter.post(name: PlacePublisher.placeSaved, object: payload)
    }

    func placeUnsaved(_ placeId: PlaceId) {
        notificationCenter.post(name: PlacePublisher.placeSaved, object: PlaceSavePayload(placeId: placeId))
    }
}
