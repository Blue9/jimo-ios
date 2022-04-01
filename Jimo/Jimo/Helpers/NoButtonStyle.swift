//
//  NoButtonStyle.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/25/22.
//

import SwiftUI

struct NoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
