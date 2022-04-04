//
//  MultilineTextField.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI

struct MultilineTextField: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding private var text: String
    
    private var placeholder: String
    private var height: CGFloat = 80
    var showingPlaceholder: Bool {
        text.isEmpty
    }
    
    init (_ placeholder: String = "", text: Binding<String>, height: CGFloat? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.height = height ?? self.height
    }
    
    var body: some View {
        TextEditor(text: $text)
            .textFieldStyle(.plain)
            .frame(minHeight: height, maxHeight: height)
            .overlay(placeholderView, alignment: .topLeading)
    }
    
    @ViewBuilder
    var placeholderView: some View {
        if showingPlaceholder {
            Text(placeholder)
                .padding(.leading, 4)
                .padding(.top, 8)
                .allowsHitTesting(false)
        }
    }
}
