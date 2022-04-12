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
    var thumbnail: Bool
    
    @Binding var imageSize: CGSize?
    
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
        .onSuccess { image, data, cacheType in
            DispatchQueue.main.async {
                self.imageSize = image.size
            }
        }
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

    init(
        url: String?,
        loading: Image? = nil,
        thumbnail: Bool = false,
        imageSize: Binding<CGSize?>? = nil
    ) {
        self.url = url
        self.loading = loading
        self.thumbnail = thumbnail
        if let imageSize = imageSize {
            self._imageSize = imageSize
        } else {
            self._imageSize = Binding.constant(nil)
        }
    }
}
