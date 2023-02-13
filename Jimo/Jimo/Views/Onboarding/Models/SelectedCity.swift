//
//  SelectedCity.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/12/23.
//

import SwiftUI

enum SelectedCity: Equatable {
    case nyc, la, chicago, london, other

    var name: String {
        switch self {
        case .nyc: return "New York"
        case .la: return "Los Angeles"
        case .chicago: return "Chicago"
        case .london: return "London"
        case .other: return "Other"
        }
    }
}
