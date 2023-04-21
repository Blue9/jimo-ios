//
//  CreatePostCategoryPicker.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/6/23.
//

import SwiftUI

struct CreatePostCategoryPicker: View {
    @Binding var category: String?

    var body: some View {
        VStack {
            HStack {
                Text("Select category")
                    .font(.system(size: 15))
                    .bold()
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    CreatePostCategory(name: "Food", key: "food", selected: $category)
                    CreatePostCategory(name: "Cafe", key: "cafe", selected: $category)
                    CreatePostCategory(name: "Nightlife", key: "nightlife", selected: $category)
                    CreatePostCategory(name: "Activity", key: "activity", selected: $category)
                    CreatePostCategory(name: "Shopping", key: "shopping", selected: $category)
                    CreatePostCategory(name: "Lodging", key: "lodging", selected: $category)
                }
            }
        }
    }
}

private struct CreatePostCategory: View {
    var name: String
    var key: String
    @Binding var selected: String?

    var colored: Bool {
        selected == nil || selected == key
    }

    var body: some View {
        VStack {
            Image(key)
                .resizable()
                .scaledToFit()
                .frame(height: 30)

            Text(name)
                .font(.system(size: 10))
                .foregroundColor(.black)
        }
        .padding(.vertical, 7.5)
        .frame(width: 60, height: 60)
        .background(colored ? Color(key) : Color("unselected"))
        .cornerRadius(10)
        .onTapGesture {
            self.selected = self.selected == key ? nil : key
        }
    }
}
