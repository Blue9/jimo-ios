//
//  URLImage.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/8/20.
//

import SwiftUI
import Kingfisher

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
    
    var processors: [ImageProcessor] {
        if thumbnail {
            return [DownsamplingImageProcessor(size: CGSize(width: 150, height: 150))]
        }
        return []
    }
    
    var body: some View {
        KFImage(realUrl)
            .onSuccess { result in
                self.imageSize = result.image.size
            }
            .cacheOriginalImage()
            .setProcessors(processors)
            .scaleFactor(UIScreen.main.scale)
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
