//
//  ContactsPermissions.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/28/22.
//

import SwiftUI
import Contacts

extension PermissionManager {
    func requestContacts(_ callback: @escaping (Bool, Error?) -> Void) {
        if contactsAuthStatus() == .denied {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, completionHandler: nil)
        }
        contactStore.requestAccess(for: .contacts, completionHandler: callback)
    }

    func contactsAuthStatus() -> PermissionStatus {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            return .notRequested
        case .authorized:
            return .authorized
        case .restricted:
            return .authorized
        case .denied:
            return .denied
        @unknown default:
            return .notRequested
        }
    }
}
