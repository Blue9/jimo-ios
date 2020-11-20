//
//  View+hideKeyboard.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/14/20.
//

import SwiftUI

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
