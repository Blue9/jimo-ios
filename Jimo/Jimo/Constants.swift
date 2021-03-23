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
        Color("activity"),
        Color("attraction"),
        Color("lodging"),
        Color("shopping")
    ]
    
    static let gradientColors = Gradient(colors: colors)
    
    static let linearGradient = LinearGradient(
        gradient: gradientColors, startPoint: .leading, endPoint: .trailing)
    
    static let linearGradientReversed = LinearGradient(
        gradient: gradientColors, startPoint: .leading, endPoint: .trailing)
}
