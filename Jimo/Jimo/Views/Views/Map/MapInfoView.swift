//
//  MapInfoView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/22/22.
//

import SwiftUI

struct MapInfoView: View {
    @Binding var presented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 5) {
                Spacer()
                Text("Welcome to the")
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44)
                Text("Map")
                Spacer()
            }
            .font(.system(size: 16, weight: .bold))
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Below are some key tips").frame(maxWidth: .infinity, alignment: .center)
                
                BulletedText("Tap on the categories at the top of the screen to filter by your preference.")
                BulletedText("Use the search bar to filter people's pins on the map.")
                BulletedText("Tap on a pin to view more information about the place. Tap anywhere outside to return to the filters.")
            }
            
            HStack {
                Spacer()
                Text("Love you, the Jimo team")
            }
            
            Button(action: { presented.toggle() }) {
                Text("Love you too")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .contentShape(Rectangle())
            }
        }
        .multilineTextAlignment(.leading)
        .font(.system(size: 14))
        .padding(20)
        .frame(width: 320)
        .background(BlurBackground(effect: UIBlurEffect(style: .systemThickMaterial)))
        .cornerRadius(10.0)
    }
}

fileprivate struct BulletedText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle")
                .resizable()
                .scaledToFit()
                .frame(width: 4, height: 18)
            
            Text(text)
        }
    }
}
