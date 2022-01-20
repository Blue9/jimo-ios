//
//  SearchField.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/18/22.
//

import SwiftUI

struct SearchField: View {
    @Binding var text: String
    @Binding var isActive: Bool
    
    var placeholder: String = "Search"
    
    var onCommit: () -> ()
    
    private func onEditingChanged(editStatus: Bool) {
        isActive = editStatus
        if !isActive {
            text = ""
        }
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField(placeholder, text: $text, onEditingChanged: onEditingChanged, onCommit: onCommit)
                    .frame(maxWidth: .infinity)
                
                if isActive {
                    Button(action: {
                        withAnimation {
                            self.text = ""
                        }
                    }) {
                        Image(systemName: "multiply.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray5))
            .cornerRadius(10)

            
            if isActive {
                Button(action: {
                    withAnimation {
                        self.isActive = false
                        self.text = ""
                    }
                    hideKeyboard()
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
