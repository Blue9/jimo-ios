//
//  Constants.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/26/20.
//

import SwiftUI

struct Colors {
    static let colors = [
        Color("food"),
        Color("lodging"),
        Color("activity"),
        Color("attraction"),
        Color("nightlife"),
        Color("shopping")
    ]

    static let gradientColors = Gradient(colors: colors)

    static let linearGradient = LinearGradient(
        gradient: gradientColors, startPoint: .leading, endPoint: .trailing)

    static let angularGradient = AngularGradient(colors: colors + [Color("food")], center: .center)

    static let linearGradientReversed = LinearGradient(
        gradient: gradientColors, startPoint: .leading, endPoint: .trailing)
}

struct Category: Identifiable, Hashable {
    var id: String {
        key
    }
    var name: String
    var key: String
    var colorName: String {
        key
    }
    var imageName: String {
        key
    }
}

struct Categories {
    static let categories = [
        Category(name: "Food", key: "food"),
        Category(name: "Things to do", key: "activity"),
        Category(name: "Nightlife", key: "nightlife"),
        Category(name: "Things to see", key: "attraction"),
        Category(name: "Lodging", key: "lodging"),
        Category(name: "Shopping", key: "shopping")
    ]
}

struct Stars {
    // Map instead of array so indexing is safe
    static let names = [
        0: "Not worth it",
        1: "Worth a try",
        2: "Worth a detour",
        3: "Worth a journey"
    ]
}
