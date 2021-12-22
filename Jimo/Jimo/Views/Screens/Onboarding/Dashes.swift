//
//  Dashes.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/22/21.
//

import SwiftUI

struct Dashes: View {
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 15) {
                ForEach(Colors.colors, id: \.self) { color in
                    Dash(color: color)
                }
            }
            .padding(.bottom, 30)
            .padding(.horizontal, 50)
            Spacer()
        }
    }
}

struct Dash: View {
    var color: Color
    
    var body: some View {
        Rectangle()
            .fill()
            .foregroundColor(color)
            .frame(maxWidth: 50)
            .frame(height: 2)
            .cornerRadius(2)
    }
}

struct Dashes_Previews: PreviewProvider {
    static var previews: some View {
        Dashes()
    }
}
