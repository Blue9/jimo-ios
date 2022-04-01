//
//  LargeButton.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/3/21.
//

import SwiftUI

struct LargeButton<Content: View>: View {
    
    let content: Content
    let fontSize: CGFloat
    
    init(_ text: String, fontSize: CGFloat = 24) where Content == Text {
        self.content = Text(text)
        self.fontSize = fontSize
    }
    
    init(@ViewBuilder _ content: @escaping () -> Content, fontSize: CGFloat = 24) {
        self.content = content()
        self.fontSize = fontSize
    }
    
    var body: some View {
        content
            .foregroundColor(Color("foreground"))
            .font(.system(size: fontSize))
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 60)
            .background(RoundedRectangle(cornerRadius: 10)
                            .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 4))
                            .background(Color("background")))
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

struct LargeButton_Previews: PreviewProvider {
    static var previews: some View {
        LargeButton("Click me")
    }
}
