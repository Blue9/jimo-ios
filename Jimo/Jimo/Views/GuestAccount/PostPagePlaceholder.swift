//
//  PostPagePlaceholder.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/1/23.
//

import SwiftUI

struct PostPagePlaceholder: View {
    var body: some View {
        HStack(alignment: .top) {
            Rectangle()
                .foregroundColor(.gray)
                .frame(width: 120, height: 120)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 5) {
                Text("Place name")
                    .font(.caption)
                    .fontWeight(.black)
                    .lineLimit(1)

                Group {
                    Text("username")
                        .font(.caption)
                        .fontWeight(.bold)
                    +
                    Text(String(repeating: "This could be you heree ", count: 4))
                        .font(.caption)
                }

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "heart")
                        .font(.system(size: 15))
                    Text("100").font(.caption)

                    Spacer().frame(width: 2)

                    Image(systemName: "bubble.right")
                        .font(.system(size: 15))
                        .offset(y: 1.5)
                    Text("50").font(.caption)

                    Spacer()
                }
                .foregroundColor(Color("foreground"))
            }
            .frame(height: 120)
            Spacer()
        }
    }
}
