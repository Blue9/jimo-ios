//
//  URLImage.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/8/20.
//

import SwiftUI

// From https://www.hackingwithswift.com/forums/swiftui/loading-images/3292/3299
struct URLImage: View {
    private enum LoadState {
        case loading, success, failure
    }

    private class Loader: ObservableObject {
        var data = Data()
        var state = LoadState.loading

        init(url: String?) {
            guard let someURL = url  else {
                self.state = .failure
                return
            }
            guard let parsedURL = URL(string: someURL) else {
                self.state = .failure
                return
            }

            URLSession.shared.dataTask(with: parsedURL) { data, response, error in
                if let data = data, data.count > 0 {
                    self.data = data
                    self.state = .success
                } else {
                    self.state = .failure
                }

                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }.resume()
        }
    }

    @StateObject private var loader: Loader
    var loading: Image
    var failure: Image

    var body: some View {
        selectImage()
            .resizable()
    }

    init(url: String?, loading: Image = Image(systemName: "photo"), failure: Image = Image(systemName: "multiply.circle")) {
        _loader = StateObject(wrappedValue: Loader(url: url))
        self.loading = loading
        self.failure = failure
    }

    private func selectImage() -> Image {
        switch loader.state {
        case .loading:
            return loading
        case .failure:
            return failure
        default:
            if let image = UIImage(data: loader.data) {
                return Image(uiImage: image)
            } else {
                return failure
            }
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
