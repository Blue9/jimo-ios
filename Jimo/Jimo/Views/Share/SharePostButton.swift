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
        ShareButtonView(shareAction: .post(post), size: 22)
    }
}
