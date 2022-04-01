//
//  Location.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/27/22.
//

import SwiftUI
import MapKit

extension PermissionManager {
    func requestLocation() {
        if self.locationManager.authorizationStatus == .denied {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, completionHandler: { (success) in })
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
}
