//
//  URLImage.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/8/20.
//

import SwiftUI
import SDWebImageSwiftUI

struct URLImage: View {
    var url: String?
    var loading: Image?
    var thumbnail: Bool = false

    var realUrl: URL? {
        if let url = url {
            return URL(string: url)
        }
        return nil
    }

    var maxDim: CGFloat {
        thumbnail ? 500 : 3000
    }

    var body: some View {
        WebImage(
            url: realUrl,
            context: [.imageThumbnailPixelSize: CGSize(width: maxDim, height: maxDim)]
        )
        .resizable()
        .placeholder {
            if let view = loading {
                AnyView(view.resizable())
            } else {
                AnyView(Color("background").opacity(0.9))
            }
        }
        .transition(.fade(duration: 0.1))
        .scaledToFill()
    }
}
