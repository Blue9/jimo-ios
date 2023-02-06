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

            VStack {
                HStack {
                    CreatePostCategory(name: "Food", key: "food", selected: $category)
                    CreatePostCategory(name: "Things to do", key: "activity", selected: $category)
                }

                HStack {
                    CreatePostCategory(name: "Nightlife", key: "nightlife", selected: $category)
                    CreatePostCategory(name: "Things to see", key: "attraction", selected: $category)
                }

                HStack {
                    CreatePostCategory(name: "Lodging", key: "lodging", selected: $category)
                    CreatePostCategory(name: "Shopping", key: "shopping", selected: $category)
                }
            }
        }
        .padding(.horizontal, 10)
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
        HStack {
            Image(key)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 35, maxHeight: 35)

            Spacer()

            Text(name)
                .font(.system(size: 15))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7.5)
        .background(colored ? Color(key) : Color("unselected"))
        .cornerRadius(2)
        .shadow(radius: colored ? 5 : 0)
        .frame(height: 50)
        .onTapGesture {
            self.selected = key
        }
    }
}
