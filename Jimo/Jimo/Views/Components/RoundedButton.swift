//
//  RoundedButton.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/7/20.
//

import SwiftUI

struct RoundedButton: View {
    let text: Text
    let action: () -> Void
    let backgroundColor: Color
    
    var body: some View {
        Button(action: action) {
            text
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(RoundedRectangle(cornerRadius: 100).fill(backgroundColor))
        }
    }
}

struct RoundedButton_Previews: PreviewProvider {
    static var previews: some View {
        RoundedButton(text: Text("Click me").fontWeight(.bold), action: {},
                      backgroundColor: Color(#colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9529411765, alpha: 0.9921568627)))
    }
}
