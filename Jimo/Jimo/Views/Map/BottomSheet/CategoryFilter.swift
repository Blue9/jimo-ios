//
//  CategoryFilter.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/7/22.
//

import SwiftUI
import BottomSheet

private struct CategoryView: View {
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
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 35, maxHeight: 35)

            Spacer()

            Text(category.name)
                .font(.system(size: 15))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7.5)
        .background(isSelected ? Color(key) : Color("unselected"))
        .cornerRadius(2)
        .shadow(radius: isSelected ? 5 : 0)
        .frame(height: 50)
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
    @Binding var selected: Set<Category>

    var body: some View {
        VStack {
            HStack {
                Text("Filter pins by category")
                    .font(.system(size: 15))
                    .bold()
                Spacer()
            }

            VStack {
                HStack {
                    CategoryView(selected: $selected, category: Categories.categories[0])
                    CategoryView(selected: $selected, category: Categories.categories[1])
                }

                HStack {
                    CategoryView(selected: $selected, category: Categories.categories[2])
                    CategoryView(selected: $selected, category: Categories.categories[3])
                }

                HStack {
                    CategoryView(selected: $selected, category: Categories.categories[4])
                    CategoryView(selected: $selected, category: Categories.categories[5])
                }
            }
        }
    }
}
