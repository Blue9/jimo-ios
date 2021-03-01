//
//  General.swift
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


struct FeedbackRequest: Codable {
    var contents: String
    var followUp: Bool
}


struct SimpleResponse: Codable {
    var success: Bool
}
