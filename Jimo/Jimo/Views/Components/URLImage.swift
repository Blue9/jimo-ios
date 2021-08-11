//
//  URLImage.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/8/20.
//

import SwiftUI
import SDWebImageSwiftUI

class URLImageState: ObservableObject {
    var imageHeight: Binding<CGFloat?>?
}

struct URLImage: View {
    var state = URLImageState()
    
    private var url: URL?
    private var loading: Image
    private var failure: Image
    private var maxDim: CGFloat
    
    var body: some View {
        WebImage(
            url: url,
            context: [.imageThumbnailPixelSize: CGSize(width: maxDim, height: maxDim)]
        )
        .resizable()
        .onSuccess { image, data, cacheType in
            DispatchQueue.main.async {
                self.state.imageHeight?.wrappedValue = image.size.height
            }
        }
        .placeholder {
            loading.resizable()
        }
        .transition(.fade(duration: 0.5))
        .scaledToFill()
    }

    init(
        url: String?,
        loading: Image = Image("grayRect"),
        failure: Image = Image("imageFail"),
        thumbnail: Bool = false,
        imageHeight: Binding<CGFloat?>? = nil
    ) {
        if let url = url {
            self.url = URL(string: url)
        }
        self.loading = loading
        self.failure = failure
        if thumbnail {
            self.maxDim = 500
        } else {
            self.maxDim = 3000
        }
        if let imageHeight = imageHeight {
            self.state.imageHeight = imageHeight
        }
    }
}

struct URLImage_Previews: PreviewProvider {
    static let defaultImage: Image = Image(systemName: "person.crop.circle")

    static var previews: some View {
        URLImage(url: nil, loading: defaultImage)
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100, alignment: .center)
    }
}
