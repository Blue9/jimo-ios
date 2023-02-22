//
//  ImageSelectionView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/6/23.
//

import SwiftUI

struct ImageSelectionView: View {
    @ObservedObject var createPostVM: CreatePostVM

    func imageView(image: CreatePostImage) -> some View {
        Group {
            switch image {
            case .uiImage(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
            case .webImage(_, let url):
                URLImage(url: url)
                    .scaledToFill()
                    .frame(width: 100, height: 100)
            }
        }
    }

    var body: some View {
        Group {
            HStack(spacing: 10) {
                ForEach(createPostVM.images, id: \.self) { image in
                    ZStack(alignment: .topLeading) {
                        imageView(image: image)
                            .frame(width: 100, height: 100)
                            .cornerRadius(2)
                        Button {
                            createPostVM.removeImage(image)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(Color(white: 0.9))
                                .background(Color.black)
                                .cornerRadius(13)
                                .padding(5)
                                .contentShape(Rectangle())
                        }
                    }
                }

                if createPostVM.images.count < 3 {
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .onTapGesture {
                                createPostVM.activeSheet = .imagePicker
                            }

                        Image(systemName: "plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                            .foregroundColor(Color.gray.opacity(0.5))
                    }
                    .frame(width: 100, height: 100)
                    .cornerRadius(2)
                }
            }
        }
    }
}
