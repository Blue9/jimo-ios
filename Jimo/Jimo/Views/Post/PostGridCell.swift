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
            
            Text(post.place.name)
                .font(.system(size: 12))
                .bold()
                .lineLimit(1)
            
            Text(post.place.regionName ?? "")
                .font(.system(size: 12))
                .lineLimit(1)
        }
        .padding(.bottom, 10)
    }
}
