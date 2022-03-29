//
//  PinQuickViewCard.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/22/22.
//

import SwiftUI
import SwiftUIPager

fileprivate let quickViewWidth: CGFloat = 320

struct PinQuickViewCard: View {
    @StateObject private var page: Page = Page.withIndex(1)
    @StateObject private var postIndex: Page = Page.withIndex(1)
    
    @ObservedObject var mapViewModel: MapViewModelV2
    @ObservedObject var quickViewModel: QuickViewModel
    
    var pin: MapPinV3
    
    var isLoading: Bool {
        quickViewModel.isLoading(placeId: pin.placeId, mapViewModel: mapViewModel)
    }
    
    var place: Place? {
        quickViewModel.getPlace(for: pin.placeId, mapViewModel: mapViewModel)
    }
    
    var posts: [Post] {
        quickViewModel.getPosts(for: pin.placeId, mapViewModel: mapViewModel)
    }
    
    var pageIds: [String] {
        ["placeInfo"] + posts.map { $0.id }
    }
    
    private func selectIndex(_ index: Int) {
        if page.index != index {
            withAnimation(.easeInOut(duration: 0.1)) {
                page.update(.new(index: index))
            }
        }
        if postIndex.index != index {
            withAnimation(.easeInOut(duration: 0.1)) {
                postIndex.update(.new(index: index))
            }
        }
    }
    
    @ViewBuilder var pageIndicator: some View {
        Pager(page: postIndex, data: pageIds.indices, id: \.self) { i in
            Circle()
                .fill()
                .opacity(i == postIndex.index ? 0.7 : 0.4)
                .frame(width: 6, height: 6)
                .onTapGesture {
                    selectIndex(i)
                }
        }
        .vertical()
        .preferredItemSize(CGSize(width: 6, height: 6))
        .itemSpacing(6)
        .delaysTouches(false)
        .multiplePagination()
        .onPageChanged { index in selectIndex(index) }
        .swipeInteractionArea(.page)
    }
    
    @ViewBuilder var postPages: some View {
        Pager(page: page, data: pageIds.indices, id: \.self) { index in
            Group {
                if pageIds[index] == "placeInfo" {
                    PlacePage(
                        quickViewModel: quickViewModel,
                        place: place!
                    )
                } else if let post = posts[index - 1] { /// -1 because index 0 is placeInfo
                    PostPage(post: post)
                } else {
                    EmptyView()
                }
                EmptyView()
            }
            .contentShape(Rectangle())
            .padding(.trailing)
            .padding(.vertical)
            .allowsHitTesting(index == page.index) // Fix issue where hidden pages block map gestures
        }
        .vertical()
        .sensitivity(.custom(0.10))
        .pagingPriority(.high)
        .preferredItemSize(CGSize(width: quickViewWidth, height: 150))
        .delaysTouches(true)
        .onPageChanged { index in selectIndex(index) }
        .frame(width: quickViewWidth - 15, height: 150)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if place != nil {
                pageIndicator
                    .frame(width: 15)
                postPages
            } else if isLoading {
                PinQuickViewPlaceholder()
            } else {
                Button(action: {
                    quickViewModel.loadPosts(appState: appState, mapViewModel: mapViewModel, placeId: pin.placeId)
                }) {
                    Text("Tap to load posts")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue)
                        .cornerRadius(2)
                }
            }
        }
        .frame(width: quickViewWidth, height: 150)
        .background(Color("background"))
        .clipShape(Rectangle())
        .contentShape(Rectangle())
        .cornerRadius(10)
    }
}

fileprivate struct PinQuickViewPlaceholder: View {
    let color = Color("foreground").opacity(0.3)
    
    var body: some View {
        HStack(alignment: .top) {
            Rectangle()
                .fill()
                .foregroundColor(color)
                .frame(width: 120, height: 120)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 5) {
                Rectangle()
                    .fill()
                    .foregroundColor(color)
                    .frame(width: 80, height: 12)
                
                Rectangle()
                    .fill()
                    .foregroundColor(color)
                    .frame(width: 150, height: 12)
                
                Rectangle()
                    .fill()
                    .foregroundColor(color)
                    .frame(width: 150, height: 12)
                
                Rectangle()
                    .fill()
                    .foregroundColor(color)
                    .frame(width: 150, height: 12)
            }
            
            Spacer()
        }
        .padding(.leading, 15)
    }
}
