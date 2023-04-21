//
//  AnonymousFeedPlaceholder.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/1/23.
//

import SwiftUI

struct AnonymousFeedPlaceholder: View {
    @State private var posts = [
        "nightlife",
        "shopping",
        "cafe",
        "lodging"
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                AnonymousFeedItem(category: posts[0])
                AnonymousFeedItem(category: posts[1])
                Spacer()
            }
        }.onAppear {
            posts.shuffle()
        }
    }
}

private struct AnonymousFeedItem: View {
    var category: String

    var body: some View {
        VStack {
            header

            Rectangle()
                .foregroundColor(Color(category).opacity(0.2))
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                .contentShape(Rectangle())
                .clipped()

            VStack(spacing: 5) {
                Text("Place name")
                    .font(.system(size: 16))
                    .bold()
                    .foregroundColor(Color("foreground"))
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                Text("Post caption goes here. Jimo baby. Let's go Jimo. How are you reading this???")
                    .font(.system(size: 13))
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, minHeight: 10, alignment: .leading)
            }
            VStack(alignment: .leading) {
                Text("100 likes - 50 comments").font(.caption)
                    .padding(.horizontal, 10)

                HStack(spacing: 0) {
                    HStack {
                        Image(systemName: "heart")
                            .font(.system(size: 20))
                            .foregroundColor(Color("foreground"))
                        Text("Like").font(.system(size: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)

                    Divider().padding(.vertical, 5)

                    HStack {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 20))
                            .foregroundColor(Color("foreground"))
                            .offset(y: 1.5)
                        Text("Comment").font(.system(size: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)

                    Divider().padding(.vertical, 5)

                    HStack {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color("foreground"))
                        Text("Save").font(.system(size: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                }
            }

            Rectangle()
                .frame(maxWidth: .infinity)
                .frame(height: 8)
                .foregroundColor(Color("foreground").opacity(0.1))
        }
    }

    @ViewBuilder
    var header: some View {
        HStack {
            Circle()
                .foregroundColor(.gray)
                .frame(width: 37, height: 37)

            VStack(alignment: .leading) {
                Text("username")
                    .font(.system(size: 16))
                    .bold()
                    .foregroundColor(Color("foreground"))

                HStack(spacing: 0) {
                    Text(category.capitalized)
                        .foregroundColor(Color(category))
                        .bold()
                    Text(" · ")
                        .foregroundColor(.gray)
                    Text("just now")
                        .foregroundColor(.gray)
                }
                .font(.system(size: 12))
                .lineLimit(1)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.subheadline)
                .frame(height: 26)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
        }
        .padding(.leading, 10)
    }
}
