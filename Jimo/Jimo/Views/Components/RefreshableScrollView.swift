//
//  RefreshableScrollView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/15/21.
//

import SwiftUI

typealias OnFinish = () -> Void
typealias OnRefresh = (@escaping OnFinish) -> Void

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

private let loadingPlaceholders = [
    "✈️",
    "🌎",
    "🌇",
    "🧭",
    "🏔️",
    "🏖️",
    "🏛️",
    "🏞️",
    "🏟️",
    "⛵",
    "🚀",
    "🪂",
    "🗺️",
]

struct RefreshableScrollView<Content: View>: View {
    @Environment(\.backgroundColor) var backgroundColor
    @State private var previousOffset: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var refreshing = false
    @State private var frozen = false
    @State private var placeholder = loadingPlaceholders.randomElement()
    
    let threshold: CGFloat = 80
    var content: Content
    var onRefresh: OnRefresh?
    
    init(@ViewBuilder content: () -> Content, onRefresh: OnRefresh? = nil) {
        self.content = content()
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .top) {
                offsetReader
                
                content
                    .alignmentGuide(.top, computeValue: { dimension in
                        refreshing && frozen ? -threshold : 0
                    })
                topView
            }
        }
        .coordinateSpace(name: "frameLayer")
        .onPreferenceChange(OffsetPreferenceKey.self, perform: onOffsetChange)
    }
    
    var topView: some View {
        Group {
            if refreshing {
                ProgressView()
            } else {
                Text(placeholder ?? "🌎")
                    .font(.title)
                    .opacity(offset < 40 ? 0 : (offset < threshold ? Double((offset - 40) / (threshold - 40)) : 1.0))
            }
        }
        .frame(height: threshold)
        .offset(y: refreshing && frozen ? 0 : -threshold)
    }
    
    var offsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: OffsetPreferenceKey.self,
                    value: proxy.frame(in: .named("frameLayer")).minY
                )
        }
        .frame(height: 0)
    }
    
    func onFinish() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        var newPlaceholder = loadingPlaceholders.randomElement()
        while placeholder == newPlaceholder {
            newPlaceholder = loadingPlaceholders.randomElement()
        }
        placeholder = newPlaceholder
        withAnimation {
            self.refreshing = false
            self.frozen = false
        }
    }
    
    private func onOffsetChange(offset: CGFloat) {
        self.offset = offset
        if !refreshing && previousOffset <= threshold && offset > threshold {
            if let onRefresh = onRefresh {
                refreshing = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onRefresh(onFinish)
            }
        }
        if refreshing && previousOffset > threshold && offset <= threshold {
            self.frozen = true
        }
        previousOffset = offset
    }
}

struct RefreshableScrollView_Previews: PreviewProvider {
    static var previews: some View {
        RefreshableScrollView {
            VStack {
                Text("Hi").frame(height: 400)
                Text("Hi").frame(height: 400)
                Text("Hi").frame(height: 400)
                Text("Hi").frame(height: 400)
                Text("Hi").frame(height: 400)
                Text("Hi").frame(height: 400)
            }
        } onRefresh: { onFinish in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                onFinish()
            }
        }
    }
}
