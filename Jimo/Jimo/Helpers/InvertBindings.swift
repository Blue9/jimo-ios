//
//  InvertBindings.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/27/22.
//

import SwiftUI

prefix func ! (value: Binding<Bool>) -> Binding<Bool> {
    Binding<Bool>(
        get: { !value.wrappedValue },
        set: { value.wrappedValue = !$0 }
    )
}
