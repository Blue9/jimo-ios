//
//  Location.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/27/22.
//

import SwiftUI
import MapKit

extension PermissionManager: CLLocationManagerDelegate {
    func requestLocation() {
        self.locationManager.delegate = self
        if self.locationManager.authorizationStatus == .denied {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, completionHandler: { (_) in })
        }
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }

    func getLocation() -> CLLocation? {
        return self.locationManager.location
    }

    func hasRequestedLocation() -> Bool {
        return self.locationManager.authorizationStatus != .notDetermined
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .denied {
            Analytics.track(.locationPermissionsDenied)
        } else if manager.authorizationStatus == .authorizedWhenInUse {
            Analytics.track(.locationPermissionsAllowed)
        }
    }
}
