//
//  CommentInputField.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/8/21.
//

import SwiftUI

struct CommentInputField: View {
    @Binding var text: String
    var submitting: Bool
    
    var buttonColor: Color = .black
    
    var onSubmit: () -> Void
    
    var inputBody: some View {
        TextField("Add a comment", text: $text)
            .disabled(submitting)
            .padding(.trailing, 25)
            .font(.system(size: 12))
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(Color("foreground").opacity(0.2))
            .cornerRadius(10)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            inputBody
            
            Group {
                if text.count > 0 {
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            hideKeyboard()
                            onSubmit()
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(buttonColor)
                    }
                    .padding(.trailing, 10)
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .animation(.easeInOut, value: text.count)
        .padding(8)
        .background(Color("background"))
    }
}
