//
//  RoundedButton.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/7/20.
//

import SwiftUI

struct RoundedButton: View {
    var text: String
    var action: () -> Void
    var backgroundColor: Color = Color(#colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9529411765, alpha: 0.9921568627))
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(width: 340, height: 60, alignment: .center)
                .background(RoundedRectangle(cornerRadius: 100).fill(backgroundColor))
        }
    }
}

struct RoundedButton_Previews: PreviewProvider {
    static var previews: some View {
        RoundedButton(text: "Click me", action: {})
    }
}
