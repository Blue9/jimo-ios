//
//  RefreshableScrollView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/15/21.
//

import SwiftUI


private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

struct RefreshableScrollView<Content: View>: View {
    @State private var previousOffset: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var refreshing = false
    @State private var frozen = false
    
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
                    .padding(.bottom, 98)
                    .alignmentGuide(.top, computeValue: { dimension in
                        refreshing && frozen ? -threshold : 0
                    })
                topView
            }
        }
        .coordinateSpace(name: "frameLayer")
        .onPreferenceChange(OffsetPreferenceKey.self, perform: onOffsetChange)
    }
    
    var arrowRotationDegrees: CGFloat {
        if offset < 40 {
            return 0
        } else if offset > threshold {
            return 180
        } else {
            return 180 * (offset - 40) / (threshold - 40)
        }
    }
    
    var topView: some View {
        Group {
            if refreshing {
                ProgressView()
            } else {
                Image(systemName: "arrow.down")
                    .opacity(0.5)
                    .font(.system(size: 20))
                    .scaledToFit()
                    .rotationEffect(Angle(degrees: arrowRotationDegrees))
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
        self.refreshing = false
        self.frozen = false
    }
    
    private func onOffsetChange(offset: CGFloat) {
        self.offset = offset
        if !refreshing && previousOffset <= threshold && offset > threshold {
            if let onRefresh = onRefresh {
                withAnimation {
                    refreshing = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onRefresh(onFinish)
                }
            }
        }
        if refreshing && previousOffset > threshold && offset <= threshold {
            withAnimation {
                self.frozen = true
            }
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
