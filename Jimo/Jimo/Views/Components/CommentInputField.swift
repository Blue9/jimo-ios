//
//  CommentInputField.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/8/21.
//

import SwiftUI

struct CommentInputField: View {
    @Environment(\.backgroundColor) var backgroundColor
    @Binding var text: String
    @State private var isActive = false
    
    var buttonColor: Color = .black
    
    var onSubmit: () -> Void
    
    var inputBody: some View {
        TextField("Add a comment", text: $text, onEditingChanged: { active in
            withAnimation {
                self.isActive = active
            }
        })
        .padding(.trailing, 25)
        .font(Font.custom(Poppins.regular, size: 12))
        .padding(.horizontal, 5)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(Color.white)
        )
        .overlay(
            HStack {
                Spacer()
                if isActive && text.count > 0 {
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
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(backgroundColor)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                inputBody
                
                if isActive {
                    Button(action: {
                        withAnimation {
                            self.isActive = false
                        }
                        onSubmit()
                        hideKeyboard()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(buttonColor)
                    }
                    .padding(.trailing, 10)
                    .transition(.move(edge: .trailing))
                }
            }
            .background(backgroundColor)
            Divider()
        }
    }
}

struct CommentInputField_Previews: PreviewProvider {
    @State static var text = ""
    
    static var previews: some View {
        CommentInputField(text: $text, onSubmit: {})
    }
}
