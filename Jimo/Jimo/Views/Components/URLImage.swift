//
//  URLImage.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/8/20.
//

import SwiftUI
import SDWebImageSwiftUI

fileprivate class LoadState {
    var imageSize: Binding<CGSize>?
}

struct URLImage: View {
    private var loadState = LoadState()
    
    private var url: URL?
    private var loading: Image?
    private var maxDim: CGFloat
    
    var body: some View {
        WebImage(
            url: url,
            context: [.imageThumbnailPixelSize: CGSize(width: maxDim, height: maxDim)]
        )
        .resizable()
        .onSuccess { image, data, cacheType in
            DispatchQueue.main.async {
                self.loadState.imageSize?.wrappedValue = image.size
            }
        }
        .placeholder {
            if let view = loading {
                AnyView(view.resizable())
            } else {
                AnyView(Color("secondary"))
            }
        }
        .transition(.fade(duration: 0.5))
        .scaledToFill()
    }

    init(
        url: String?,
        loading: Image? = nil,
        thumbnail: Bool = false,
        imageSize: Binding<CGSize>? = nil
    ) {
        if let url = url {
            self.url = URL(string: url)
        }
        self.loading = loading
        if thumbnail {
            self.maxDim = 500
        } else {
            self.maxDim = 3000
        }
        if let imageSize = imageSize {
            self.loadState.imageSize = imageSize
        }
    }
}
