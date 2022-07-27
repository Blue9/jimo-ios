//
//  PermissionManager.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/27/22.
//

import SwiftUI
import Contacts
import MapKit

enum PermissionStatus {
    case notRequested, authorized, denied
}

class PermissionManager: NSObject {
    static let shared = PermissionManager()
    
    let locationManager = CLLocationManager()
    let contactStore = CNContactStore()
}
