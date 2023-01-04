//
//  MapSearchResultBody.swift
//  Jimo
//
//  Created by admin on 12/23/22.
//

import SwiftUI
import SwiftUIPager

fileprivate var color = Color(red: 72.0 / 255, green: 159.0 / 255, blue: 240.0 / 255)

struct MapSearchResultBody: View {
    var result: MapPlaceResult

    var body: some View {
        ScrollView(showsIndicators: false) {
            HStack {
                CreatePostButton(result: result)
            }
            
            HStack {
                if let phoneNumber = result.mkMapItem?.phoneNumber {
                    PhoneNumberButton(phoneNumber: phoneNumber)
                }
                if let url = result.mkMapItem?.url {
                    WebsiteButton(url: url)
                }
                OpenInMapsButton(result: result)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .foregroundColor(.white)
            .padding(.bottom, 10)
            VStack {
                if result.followingPosts.count > 0 {
                    PostCarousel(text: "Friends' Posts", posts: result.followingPosts)
                }
                
                if result.featuredPosts.count > 0 {
                    PostCarousel(text: "Featured", posts: result.featuredPosts)
                }
                
                if result.communityPosts.count > 0 {
                    PostCarousel(text: "Community", posts: result.communityPosts)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)
        }
        .padding(.bottom, 49)
    }
}

fileprivate struct CreatePostButton: View {
    @StateObject var createPostVM = CreatePostVM()
    @State private var showCreatePost = false

    var result: MapPlaceResult
    
    var body: some View {
        Button {
            if let place = result.details?.place {
                createPostVM.selectPlace(place: place)
            } else if let mapItem = result.mkMapItem {
                createPostVM.selectPlace(place: mapItem)
            }
            showCreatePost = true
        } label: {
            HStack {
                Spacer()
                Text("Make a post")
                    .font(.system(size: 15))
                    .fontWeight(.medium)
                Image(systemName: "plus.app")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                Spacer()
            }
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(color)
            .cornerRadius(5)
            .padding(.horizontal, 10)
        }.disabled(result.details == nil && result.mkMapItem == nil)
        
        .sheet(isPresented: $showCreatePost) {
            CreatePost(createPostVM: createPostVM, presented: $showCreatePost)
        }
    }
}

fileprivate struct PhoneNumberButton: View {
    var phoneNumber: String
    
    var body: some View {
        Button {
            if let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                UIApplication.shared.open(url)
            }
        } label: {
            VStack {
                Image(systemName: "phone.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                Text("Call")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 70, height: 75)
            .foregroundColor(color)
            .background(Color("foreground").opacity(0.1))
            .cornerRadius(5)
        }
    }
}

fileprivate struct WebsiteButton: View {
    var url: URL
    
    var body: some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            VStack {
                Image(systemName: "globe")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                Text("Website")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 70, height: 75)
            .foregroundColor(color)
            .background(Color("foreground").opacity(0.1))
            .cornerRadius(5)
        }
    }
}

fileprivate struct OpenInMapsButton: View {
    var result: MapPlaceResult
    
    var body: some View {
        Button {
            openInMaps(place: result)
        } label: {
            VStack {
                Image(systemName: "arrow.up.right.square")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                Text("Maps")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 70, height: 75)
            .foregroundColor(color)
            .background(Color("foreground").opacity(0.1))
            .cornerRadius(5)
        }
    }
    
    private func openInMaps(place: MapPlaceResult) {
        if (UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!)) {
            openInGoogleMaps(place: place)
        } else {
            openInAppleMaps(place: place)
        }
    }
    
    private func openInGoogleMaps(place: MapPlaceResult) {
        let scheme = "comgooglemaps://"
        let query = place.name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? place.name
        let url = "\(scheme)?q=\(query)&center=\(place.latitude),\(place.longitude)"
        UIApplication.shared.open(URL(string: url)!)
    }
    
    private func openInAppleMaps(place: MapPlaceResult) {
        let q = place.name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? place.name
        let sll = "\(place.latitude),\(place.longitude)"
        let url = "http://maps.apple.com/?q=\(q)&sll=\(sll)&z=10"
        if let encoded = url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
           let url = URL(string: encoded) {
            UIApplication.shared.open(url)
        } else {
            print("URL not valid", url)
        }
    }
}

fileprivate struct PostCarousel: View {
    @StateObject var page: Page = .first()
    
    var text: String
    var posts: [Post]
    
    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 15))
                .bold()
            Spacer()
        }
        
        Pager(page: page, data: posts) { post in
            PostPage(post: post)
                .contentShape(Rectangle())
        }
        .padding(10)
        .alignment(.start)
        .sensitivity(.custom(0.10))
        .pagingPriority(.high)
        .frame(height: 120)
    }
}
