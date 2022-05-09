//
//  Constants.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/26/20.
//

import SwiftUI

struct Colors {
    static let colors = PostCategory.allCases.map { $0.color }

    static let gradientColors = Gradient(colors: colors)

    static let linearGradient = LinearGradient(
        gradient: gradientColors, startPoint: .leading, endPoint: .trailing)

    static let angularGradient = AngularGradient(colors: colors + [Color("food")], center: .center)

    static let linearGradientReversed = LinearGradient(
        gradient: gradientColors, startPoint: .leading, endPoint: .trailing)
}
