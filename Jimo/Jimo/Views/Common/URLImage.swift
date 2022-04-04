//
//  URLImage.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/8/20.
//

import SwiftUI
import Kingfisher

fileprivate class LoadState {
    var imageSize: Binding<CGSize>?
}

struct URLImage: View {
    private var loadState = LoadState()
    
    private var url: URL?
    private var loading: Image?
    private var thumbnail: Bool
    
    var processors: [ImageProcessor] {
        if thumbnail {
            return [DownsamplingImageProcessor(size: CGSize(width: 150, height: 150))]
        }
        return []
    }
    
    var body: some View {
        KFImage(url)
            .setProcessors(processors)
            .scaleFactor(UIScreen.main.scale)
            .cacheOriginalImage()
            .cancelOnDisappear(true)
            .onSuccess { result in
                if self.loadState.imageSize != nil && self.loadState.imageSize?.wrappedValue == nil {
                    DispatchQueue.main.async {
                        self.loadState.imageSize?.wrappedValue = result.image.size
                    }
                }
            }
            .placeholder {
                if let view = loading {
                    view.resizable()
                } else {
                    Color("background").opacity(0.9)
                }
            }
            .resizable()
            .fade(duration: 0.1)
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
        self.thumbnail = thumbnail
        if let imageSize = imageSize {
            self.loadState.imageSize = imageSize
        }
    }
}
