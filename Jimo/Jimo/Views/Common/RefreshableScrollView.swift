//
//  RefreshableScrollView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/15/21.
//

import SwiftUI

struct RefreshableScrollView<Content: View>: View {
    var spacing: CGFloat?
    var content: () -> Content
    var onRefresh: OnRefresh
    var onLoadMore: OnLoadMore?

    init(
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content,
        onRefresh: @escaping OnRefresh,
        onLoadMore: OnLoadMore? = nil
    ) {
        self.spacing = spacing
        self.content = content
        self.onRefresh = onRefresh
        self.onLoadMore = onLoadMore
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: spacing) {
                content()
                Color("background")
                    .frame(height: UIScreen.main.bounds.height)
                    .appear {
                        onLoadMore?()
                    }
                Spacer()
            }
        }
        .refreshable {
            onRefresh({})
        }
    }
}
