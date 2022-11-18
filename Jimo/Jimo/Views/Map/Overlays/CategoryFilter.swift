//
//  CategoryFilter.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/7/22.
//

import SwiftUI
import BottomSheet

struct CategoryView: View {
    @Binding var selected: Set<Category>
    
    var category: Category
    
    var key: String {
        category.key
    }
    
    var isSelected: Bool {
        selected.contains(category)
    }
    
    var allSelected: Bool {
        selected.count == Categories.categories.count
    }
    
    var onlySelected: Bool {
        isSelected && selected.count == 1
    }
    
    var body: some View {
        HStack {
            Image(key)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 20, maxHeight: 20)
            Text(category.name)
                .font(.system(size: 15))
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .foregroundColor(.black.opacity(0.9))
        .padding(8)
        .background(isSelected ? Color(key) : Color("unselected"))
        .cornerRadius(10)
        // TODO tap gestures broken in scroll view, this explicit height is a hack to get it to work
        .contentShape(Rectangle())
        .frame(height: 60)
        .onTapGesture {
            if allSelected {
                self.selected = [category]
            } else if onlySelected {
                self.selected = Set(Categories.categories)
            } else if isSelected {
                self.selected.remove(category)
            } else {
                self.selected.insert(category)
            }
        }
    }
}


struct CategoryFilter: View {
    @Binding var selectedCategories: Set<Category>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Categories.categories) { category in
                    CategoryView(selected: $selectedCategories, category: category)
                }
            }
            .padding(.horizontal)
        }.frame(width: UIScreen.main.bounds.width)
    }
}
