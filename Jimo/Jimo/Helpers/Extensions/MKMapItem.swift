//
//  MKMapItem.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/19/23.
//

import MapKit

extension MKMapItem {
    var circularRegion: Region? {
        if let area = self.placemark.region as? CLCircularRegion {
            return Region(coord: area.center, radius: area.radius.magnitude)
        }
        return nil
    }

    var maybeCreatePlaceRequest: MaybeCreatePlaceRequest? {
        guard let name = self.name else {
            return nil
        }
        return MaybeCreatePlaceRequest(
            name: name,
            location: Location(coord: self.placemark.coordinate),
            region: self.circularRegion,
            additionalData: AdditionalPlaceDataRequest(self)
        )
    }
}
