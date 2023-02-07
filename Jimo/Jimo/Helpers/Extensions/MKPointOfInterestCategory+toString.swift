//
//  MKPointOfInterestCategory+toString.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/7/23.
//

import MapKit

extension MKPointOfInterestCategory {
    func toString() -> String {
        return self.rawValue.replacingOccurrences(of: "MKPOICategory", with: "")
    }
}
