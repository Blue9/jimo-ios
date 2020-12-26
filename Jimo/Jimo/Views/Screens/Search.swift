//
//  Search.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/13/20.
//

import SwiftUI

enum SearchType {
    case people
    case places
}

struct Search: View {
    @State var query: String = ""
    @State var searchType: SearchType = .people

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $query, placeholder: "Search")
                    .padding(.bottom, 0)
                Picker(selection: $searchType, label: Text("What do you want to search for")) {
                    Text("People").tag(SearchType.people)
                    Text("Places").tag(SearchType.places)
                }
                .pickerStyle(SegmentedPickerStyle())
                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct Search_Previews: PreviewProvider {
    
    static var previews: some View {
        Search()
    }
}
