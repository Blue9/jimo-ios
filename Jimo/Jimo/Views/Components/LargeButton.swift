//
//  LargeButton.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/3/21.
//

import SwiftUI

struct LargeButton: View {
    let text: String
    let fontSize: CGFloat
    
    init(_ text: String, fontSize: CGFloat = 24) {
        self.text = text
        self.fontSize = fontSize
    }
    
    var body: some View {
        Text(text)
            .font(Font.custom(Poppins.medium, size: fontSize))
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 60)
            .foregroundColor(Color("food"))
            .background(RoundedRectangle(cornerRadius: 10)
                            .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 4))
                            .background(Color.white))
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

struct LargeButton_Previews: PreviewProvider {
    static var previews: some View {
        LargeButton("Click me")
    }
}
