//
//  SearchBar.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/9/20.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var isActive: FocusState<Bool>.Binding

    var placeholder: String = "Search"
    var disableAutocorrection: Bool = false
    var onCommit: () -> Void

    var body: some View {
        HStack {
            TextField(placeholder, text: $text, onCommit: onCommit)
                .focused(isActive)
                .disableAutocorrection(disableAutocorrection)
                .textContentType(.location)
                .padding(8)
                .padding(.horizontal, 25)
                .background(Color(.systemGray5))
                .cornerRadius(10)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        if isActive.wrappedValue {
                            Button(action: {
                                withAnimation {
                                    self.text = ""
                                }
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )

            if isActive.wrappedValue {
                Button(action: {
                    withAnimation {
                        DispatchQueue.main.async {
                            self.isActive.wrappedValue = false
                            self.text = ""
                        }
                    }
                }) {
                    Text("Cancel")
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
            }
        }
        .padding(.vertical, 6)
    }
}
