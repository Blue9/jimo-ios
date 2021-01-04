//
//  NavTitle.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/2/21.
//

import SwiftUI

struct NavTitle: View {
    
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title).font(Font.custom(Poppins.medium, size: 18))
    }
}
