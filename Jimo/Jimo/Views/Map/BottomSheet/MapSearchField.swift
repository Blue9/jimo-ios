//
//  MapSearchField.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/18/22.
//

import SwiftUI

struct MapSearchField: View {
    @Binding var text: String
    var isActive: FocusState<Bool>.Binding
    
    var placeholder: String = "Search"
    
    var onCommit: () -> ()
    
    var body: some View {
        HStack {
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField(placeholder, text: $text, onCommit: onCommit)
                    .textContentType(.location)
                    .focused(isActive)
                    .submitLabel(.search)
                    .frame(maxWidth: .infinity)
                
                if isActive.wrappedValue {
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
            .background(Color("foreground").opacity(0.1))
            .cornerRadius(10)

            
            if isActive.wrappedValue {
                Button(action: {
                    withAnimation {
                        self.isActive.wrappedValue = false
                        self.text = ""
                    }
                    hideKeyboard()
                }) {
                    Text("Cancel")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
