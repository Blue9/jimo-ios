//
//  Environment.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/18/21.
//

import SwiftUI

struct BackgroundColorEnvironmentKey: EnvironmentKey {
    static let defaultValue: Color = .white
}

extension EnvironmentValues {
    var backgroundColor: Color {
        get {
            return self[BackgroundColorEnvironmentKey]
        }
        set {
            self[BackgroundColorEnvironmentKey] = newValue
        }
    }
}

