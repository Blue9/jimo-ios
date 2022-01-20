//
//  MapQuickView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/11/22.
//

import SwiftUI
import MapKit
import SwiftUIPager

fileprivate let quickViewWidth: CGFloat = 320

struct MapQuickView: View {
    @StateObject var quickViewModel = QuickViewModel()
    
    @ObservedObject var page: Page
    @ObservedObject var mapViewModel: MapViewModelV2
    
    var onPageChanged: (Int) -> ()
    
    @ViewBuilder var quickViewBody: some View {
        Pager(page: page, data: mapViewModel.mapPins.pins) { pin in
            PlaceQuickView(mapViewModel: mapViewModel, quickViewModel: quickViewModel, pin: pin)
        }
        .itemSpacing(20)
        .preferredItemSize(CGSize(width: quickViewWidth, height: 150))
        .delaysTouches(false)
        .pagingPriority(.simultaneous)
        .loopPages()
        .onPageChanged(onPageChanged)
        .frame(width: UIScreen.main.bounds.width, height: 200)
    }
    
    var body: some View {
        if mapViewModel.mapPins.pins.count > 0 {
            quickViewBody
        }
    }
}

fileprivate struct PlaceQuickView: View {
    @StateObject private var page: Page = Page.withIndex(1)
    @StateObject private var postIndex: Page = Page.withIndex(1)
    
    @ObservedObject var mapViewModel: MapViewModelV2
    @ObservedObject var quickViewModel: QuickViewModel

    var pin: MapPlace
    
    var pageIds: [String] {
        ["placeInfo"] + pin.posts
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
                    PlaceInfoQuickView(
                        quickViewModel: quickViewModel,
                        locationManager: mapViewModel.locationManager,
                        place: pin.place
                    )
                } else if let post = mapViewModel.allPosts[pageIds[index]] {
                    SinglePostQuickView(post: post)
                } else {
                    EmptyView()
                }
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
            pageIndicator
                .frame(width: 15)
            postPages
        }
        .background(Color("background"))
        .frame(width: quickViewWidth, height: 150)
        .clipShape(Rectangle())
        .contentShape(Rectangle())
        .cornerRadius(10)
    }
}
