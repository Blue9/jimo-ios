//
//  MapSearchBar.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/7/21.
//

import SwiftUI

struct MapSearchBar: View {
    @Binding var text: String
    
    var placeholder: String = "Search"
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding(8)
            .padding(.horizontal, 25)
            .cornerRadius(100)
            .overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                    
                    if text.count > 0 {
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
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Color(.systemGray6)
                    .cornerRadius(100)
                    .shadow(radius: text.count > 0 ? 1 : 5)
            )
    }
}

struct MapSearchBar_Previews: PreviewProvider {
    
    static var previews: some View {
        MapSearchBar(text: .constant("query"))
    }
}
