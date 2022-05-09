//
//  CategoryFilter.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/7/22.
//

import SwiftUI
import BottomSheet

struct CategoryView: View {
    var name: String
    var key: String
    
    @Binding var selected: Set<String>
    
    var isSelected: Bool {
        selected.contains(key)
    }
    
    var allSelected: Bool {
        selected.count == PostCategory.allCases.count
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
            Text(name)
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
                self.selected = [key]
            } else if onlySelected {
                self.selected = Set(PostCategory.allCases.map({ $0.rawValue }))
            } else if isSelected {
                self.selected.remove(key)
            } else {
                self.selected.insert(key)
            }
        }
    }
}

struct CategoryFilter: View {
    @Binding var selectedCategories: Set<String>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PostCategory.allCases, id: \.self) { category in
                    CategoryView(name: category.displayName, key: category.rawValue, selected: $selectedCategories)
                }
            }
            .padding(.horizontal)
        }.frame(width: UIScreen.main.bounds.width)
    }
}
