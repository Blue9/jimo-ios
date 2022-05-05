//
//  SharePostButton.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/5/22.
//

import SwiftUI
import SDWebImage

struct SharePostButton: View {
    var post: Post
    
    var body: some View {
        if let url = post.postUrl {
            ShareButtonView(shareType: .post, url: url, size: 22)
        }
    }
}
