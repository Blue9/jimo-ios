//
//  CreatePostStarPicker.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/6/23.
//

import SwiftUI

struct CreatePostStarPicker: View {
    var unselectedOutline: Color = .gray
    var showZeroStars: Bool = true
    @Binding var stars: Int?

    // Makes comparisons easier
    var effectiveStars: Int {
        stars ?? -1
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                if showZeroStars {
                    Star(fg: unselectedOutline, systemImagePrefix: "star.slash", selected: effectiveStars == 0) {
                        stars = stars == 0 ? nil : 0
                    }
                    Spacer()
                }
                Star(fg: unselectedOutline, selected: effectiveStars >= 1) {
                    stars = stars == 1 ? nil : 1
                }
                Spacer()
                Star(fg: unselectedOutline, selected: effectiveStars >= 2) {
                    stars = stars == 2 ? nil : 2
                }
                Spacer()
                Star(fg: unselectedOutline, selected: effectiveStars >= 3) {
                    stars = stars == 3 ? nil : 3
                }
            }

            HStack(spacing: 0) {
                if showZeroStars {
                    Text("Not worth it").frame(maxWidth: .infinity)
                    Spacer()
                }
                Text("Worth a stop").frame(maxWidth: .infinity)
                Spacer()
                Text("Worth a detour").frame(maxWidth: .infinity)
                Spacer()
                Text("Worth a journey").frame(maxWidth: .infinity)
            }
            .font(.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.1)
        }
        .padding(.horizontal, 10)
    }
}

private struct Star: View {
    let fg: Color
    var systemImagePrefix: String = "star"
    let selected: Bool
    let onTap: () -> Void

    var systemImageName: String {
        selected ? systemImagePrefix + ".fill" : systemImagePrefix
    }

    var body: some View {
        VStack {
            Image(systemName: systemImageName)
                .resizable()
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(selected && systemImagePrefix == "star" ? .yellow : fg)
                .scaledToFit()
                .contentShape(Rectangle())
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onTap()
                }
                .frame(width: 50)
        }.frame(maxWidth: .infinity)
    }
}
