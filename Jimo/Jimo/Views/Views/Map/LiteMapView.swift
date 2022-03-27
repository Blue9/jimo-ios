//
//  LiteMapView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/25/22.
//

import SwiftUI
import MapKit
import SwiftUIPager

fileprivate let quickViewWidth: CGFloat = 320

struct LiteMapView: View {
    let locationManager = CLLocationManager()
    
    @StateObject private var regionWrapper = RegionWrapper()
    @StateObject private var quickViewModel = QuickViewModel()
    @StateObject private var page: Page = .first()
    
    var post: Post
    
    var pin: MapPinV3 {
        MapPinV3(
            placeId: post.place.id,
            location: post.place.location,
            icon: MapPlaceIconV3(category: post.category, iconUrl: post.user.profilePictureUrl, numPosts: 1)
        )
    }
    
    @ViewBuilder var pageIndicator: some View {
        Pager(page: page, data: [0, 1], id: \.self) { i in
            Circle()
                .fill()
                .opacity(i == page.index ? 0.7 : 0.4)
                .frame(width: 6, height: 6)
        }
        .vertical()
        .preferredItemSize(CGSize(width: 6, height: 6))
        .itemSpacing(6)
        .delaysTouches(false)
        .multiplePagination()
        .swipeInteractionArea(.page)
    }
    
    @ViewBuilder var postPage: some View {
        Pager(page: page, data: [0, 1], id: \.self) { index in
            Group {
                if index == 0 {
                    PlacePage(
                        quickViewModel: quickViewModel,
                        locationManager: locationManager,
                        place: post.place
                    )
                } else {
                    PostPage(post: post)
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
        .frame(width: quickViewWidth - 15, height: 150)
    }
    
    @ViewBuilder var quickViewOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                pageIndicator
                    .frame(width: 15)
                postPage
            }
            .frame(width: quickViewWidth, height: 150)
            .background(Color("background"))
            .clipShape(Rectangle())
            .contentShape(Rectangle())
            .cornerRadius(10)
        }
        .padding()
    }
    
    var body: some View {
        MapKitViewV2(
            region: regionWrapper.region,
            selectedPin: .constant(pin),
            annotations: [PlaceAnnotationV2(pin: pin, zIndex: 1)]
        )
        .edgesIgnoringSafeArea(.top)
        .overlay(quickViewOverlay)
        .onAppear {
            regionWrapper.region.wrappedValue = MKCoordinateRegion(
                center: post.place.location.coordinate(),
                span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            )
            regionWrapper.trigger.toggle()
        }
    }
}
