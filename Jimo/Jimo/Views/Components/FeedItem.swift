//
//  FeedItem.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/8/20.
//

import SwiftUI

struct FeedItem: View {
    let post: Post

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .frame(height: 32)
                .foregroundColor(Color(post.category))
            HStack(alignment: .top) {
                URLImage(url: post.user.profilePictureUrl, failure: Image(systemName: "circle.fill"))
                    .foregroundColor(Color(#colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9529411765, alpha: 1)))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60, alignment: .center)
                    .cornerRadius(30)
                    .padding(.trailing, 6)
                    .padding(.top, 4)
                VStack(alignment: .leading) {
                    HStack {
                        Text(post.user.firstName)
                            .font(.title3)
                            .bold()
                        Spacer()
                        Text("8 min")
                            .font(.subheadline)
                    }
                    HStack {
                        Text("Place name")
                        Text("-")
                        Text("Region")
                    }
                    .font(.caption)
                    .offset(y: 6)
                    Text(post.content)
                        .padding(.top, 10)
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "heart")
                                .font(.system(size: 30))
                            Text(String(post.likeCount))
                        }
                        Spacer()
                            .frame(width: 40)
                        VStack {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 30))
                            Text(String(post.commentCount))
                        }
                    }
                    .padding(.top, 4)
                    .padding(.trailing)
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom)
        }
    }
}
