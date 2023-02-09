//
//  PostGridCell.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/11/22.
//

import SwiftUI

struct PostGridCell: View {
    var post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                if let url = post.imageUrl {
                    URLImage(url: url, thumbnail: true)
                        .frame(maxWidth: .infinity)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                } else {
                    MapSnapshotView(post: post, width: (UIScreen.main.bounds.width - 6) / 3)
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.width)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .background(Color(post.category))
            .cornerRadius(2)
            .padding(.bottom, 5)

            caption
        }
        .padding(.bottom, 10)
    }

    @ViewBuilder
    var caption: some View {
        if let stars = post.stars {
            HStack(spacing: 1) {
                if stars == 0 {
                    Image(systemName: "star.slash.fill")
                        .foregroundColor(.gray)
                } else {
                    ForEach(0..<stars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }.font(.caption)
        }
        Text(post.place.name)
            .font(.caption)
            .bold()
            .lineLimit(1)

        Text(post.place.city ?? "")
            .font(.caption)
            .lineLimit(1)
        if post.stars == nil {
            Text(" ").font(.caption) // Spacer to keep grid rows even height
        }
    }
}
