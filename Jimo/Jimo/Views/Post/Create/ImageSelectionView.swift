//
//  ImageSelectionView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/6/23.
//

import SwiftUI

struct ImageSelectionView: View {
    @ObservedObject var createPostVM: CreatePostVM

    var buttonColor: Color

    func imageView(image: CreatePostImage) -> some View {
        Group {
            switch image {
            case .uiImage(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .onTapGesture {
                        createPostVM.activeSheet = .imagePicker
                    }
            case .webImage(_, let url):
                URLImage(url: url)
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .onTapGesture {
                        createPostVM.activeSheet = .imagePicker
                    }
            }
        }
    }

    var body: some View {
        Group {
            if let image = createPostVM.image {
                ZStack(alignment: .topLeading) {
                    imageView(image: image)

                    Button {
                        createPostVM.image = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(buttonColor)
                            .background(Color.black)
                            .cornerRadius(10)
                            .padding(5)
                    }
                }
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .onTapGesture {
                            createPostVM.activeSheet = .imagePicker
                        }

                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .foregroundColor(Color.gray.opacity(0.5))
                }
            }
        }
        .frame(width: 100, height: 100)
        .cornerRadius(2)
    }
}
