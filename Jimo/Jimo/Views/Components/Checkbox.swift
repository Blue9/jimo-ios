//
//  Checkbox.swift
//  Jimo
//
//  Created by Jeff Rohlman on 2/28/21.
//

import SwiftUI

struct Checkbox: View {
    let label: String
    let boxSize: CGFloat
    @Binding var selected: Bool
    
    var body: some View {
        Button(action: {
            selected.toggle()
        }) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: self.selected ? "checkmark.square" : "square")
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: boxSize, height: boxSize)
                Text(label)
                    .font(.system(size: 12))
                Spacer()
            }
            .foregroundColor(Color("foreground"))
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
    }
}
