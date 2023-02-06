//
//  CreatePostStarPicker.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/6/23.
//

import SwiftUI

struct CreatePostStarPicker: View {
    @Binding var stars: Int?

    // Makes comparisons easier
    var effectiveStars: Int {
        stars ?? -1
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Award stars (Optional)")
                .font(.system(size: 15))
                .bold()
                .padding(.horizontal)
            HStack {
                VStack {
                    Image(systemName: stars == 0 ? "star.slash.fill" : "star.slash")
                        .resizable()
                        .font(.system(size: 15, weight: .thin))
                        .foregroundColor(.yellow)
                        .scaledToFit()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            stars = stars == 0 ? nil : 0
                        }
                    Text("Not worth")
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                Star(text: "Worth trying", selected: effectiveStars >= 1) {
                    stars = stars == 1 ? nil : 1
                }

                Star(text: "Worth a detour", selected: effectiveStars >= 2) {
                    stars = stars == 2 ? nil : 2
                }

                Star(text: "Worth a journey", selected: effectiveStars >= 3) {
                    stars = stars == 3 ? nil : 3
                }
            }
            .padding(.horizontal)

        }
    }
}

private struct Star: View {
    var text: String
    var selected: Bool
    var onTap: () -> Void

    var body: some View {
        VStack {
            Image(systemName: selected ? "star.fill" : "star")
                .resizable()
                .font(.system(size: 15, weight: .thin))
                .foregroundColor(.yellow)
                .scaledToFit()
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
            Text(text)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}
