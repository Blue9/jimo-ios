//
//  URLImage.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/8/20.
//

import SwiftUI
import Kingfisher

struct URLImage: View {
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
            .cacheOriginalImage()
            .setProcessors(processors)
            .scaleFactor(UIScreen.main.scale)
            .cancelOnDisappear(true)
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
        thumbnail: Bool = false
    ) {
        if let url = url {
            self.url = URL(string: url)
        }
        self.loading = loading
        self.thumbnail = thumbnail
    }
}
