//
//  CommentInputField.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/8/21.
//

import SwiftUI

struct CommentInputField: View {
    @Binding var text: String
    
    var buttonColor: Color = .black
    
    var onSubmit: () -> Void
    
    @ViewBuilder var inputBody: some View {
        TextField("Add a comment", text: $text)
            .padding(.trailing, 25)
            .font(.system(size: 12))
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(Color("background"))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                inputBody
                
                if text.count > 0 {
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            self.text = ""
                        }
                    }) {
                        Image(systemName: "multiply.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 8)
                    }
                    
                    Button(action: {
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
            .background(Color("background"))
            Divider()
                .foregroundColor(Color("foreground"))
        }
    }
}

struct CommentInputField_Previews: PreviewProvider {
    @State static var text = ""
    
    static var previews: some View {
        CommentInputField(text: $text, onSubmit: {})
    }
}
