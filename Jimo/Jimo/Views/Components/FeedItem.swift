//
//  FeedItem.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/8/20.
//

import SwiftUI

struct FeedItem: View {
    var name: String = "Kevin Nizza"
    var profilePicture: String?
    var placeName: String = "Kai's Hotdogs"
    var region: String = "New York, New York"
    var timeSincePost: String = "5 hrs"
    var content: String = "Mhmmh Soupy inside! Melt in Mouth. Definitely not the best that I’ve had in the world but ..."
    var likeCount = 15
    var commentCount = 15

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .frame(height: 32)
                .foregroundColor(Color(#colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)))
            HStack(alignment: .top) {
                URLImage(url: profilePicture, failure: Image(systemName: "circle.fill"))
                    .foregroundColor(Color(#colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9529411765, alpha: 1)))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60, alignment: .center)
                    .padding(.trailing, 6)
                VStack(alignment: .leading) {
                    HStack {
                        Text(name)
                            .font(.title3)
                            .bold()
                        Spacer()
                        Text(timeSincePost)
                            .font(.subheadline)
                    }
                    HStack {
                        Text(placeName)
                        Text("-")
                        Text(region)
                    }
                    .font(.caption)
                    .offset(y: 6)
                    Text(content)
                        .padding(.top, 10)
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "heart")
                                .font(.system(size: 30))
                            Text(String(likeCount))
                        }
                        Spacer()
                            .frame(width: 40)
                        VStack {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 30))
                            Text(String(commentCount))
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

struct FeedItem_Previews: PreviewProvider {
    static var previews: some View {
        FeedItem()
    }
}
