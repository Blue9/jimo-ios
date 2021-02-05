//
//  FirebaseUser.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/24/20.
//

import Foundation

struct FirebaseUser {
    var uid: String
    var phoneNumber: String?
}


struct NotificationTokenRequest: Codable {
    var token: String
}


struct NotificationTokenResponse: Codable {
    var success: Bool
}
