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
    @EnvironmentObject var appState: AppState
    
    @StateObject var page: Page = .first()
    @ObservedObject var mapViewModel: MapViewModelV2
    @ObservedObject var quickViewModel: QuickViewModel
    
    private func loadPosts(index: Int) {
        if index < 0 || index >= mapViewModel.pins.count {
            return
        }
        let pin = mapViewModel.pins[index]
        quickViewModel.loadPosts(appState: appState, mapViewModel: mapViewModel, placeId: pin.placeId!)
    }
    
    private func selectPin(pin: MKJimoPinAnnotation) {
        if let i = mapViewModel.pins.firstIndex(of: pin) {
            page.update(.new(index: i))
            quickViewModel.loadPosts(appState: appState, mapViewModel: mapViewModel, placeId: pin.placeId!)
        }
    }
    
    func loadPostsAndPreloadNextAndPrevious(index: Int) {
        loadPosts(index: index)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadPosts(index: index + 1)
            loadPosts(index: index - 1)
        }
    }
    
    @ViewBuilder var quickViewBody: some View {
        Pager(page: page, data: mapViewModel.pins) { pin in
            PinQuickViewCard(mapViewModel: mapViewModel, quickViewModel: quickViewModel, pin: pin)
        }
        .itemSpacing(20)
        .preferredItemSize(CGSize(width: quickViewWidth, height: 150))
        .delaysTouches(false)
        .pagingPriority(.simultaneous)
        .loopPages()
        .onPageChanged { index in
            print("Page changed")
            mapViewModel.selectPin(index: index)
            loadPostsAndPreloadNextAndPrevious(index: index)
        }
        .frame(width: UIScreen.main.bounds.width, height: 150)
        .padding(.bottom, 25)
        .onChange(of: mapViewModel.selectedPin) { selectedPin in
            withAnimation {
                if let selectedPin = selectedPin {
                    print("selecting pin")
                    selectPin(pin: selectedPin)
                }
            }
        }
    }
    
    var body: some View {
        if mapViewModel.pins.count > 0 {
            quickViewBody
                .onAppear {
                    if let selectedPin = mapViewModel.selectedPin {
                        selectPin(pin: selectedPin)
                    } else {
                        print("Unexpected case: no selected pin but quick view is visible")
                    }
                    loadPostsAndPreloadNextAndPrevious(index: page.index)
                }
        }
    }
}
