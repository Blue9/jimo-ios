//
//  SearchBar.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/9/20.
//

import SwiftUI

// From https://www.albertomoral.com/blog/uisearchbar-and-swiftui
struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var minimal = false
    var placeholder: String = ""
    var textFieldColor: UIColor? = nil

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            searchBar.setShowsCancelButton(true, animated: true)
        }
        
        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.setShowsCancelButton(false, animated: true)
        }
        
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            hideKeyboard()
        }
    }
    
    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        searchBar.searchBarStyle = minimal ? .minimal : .default;
        if let textFieldColor = textFieldColor {
            searchBar.searchTextField.backgroundColor = textFieldColor;
            searchBar.searchTextField.borderStyle = .roundedRect
        }
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        if uiView.text != text {
            uiView.text = text
        }
    }
}

struct SearchBar_Previews: PreviewProvider {
    @State static var text: String = ""

    static var previews: some View {
        SearchBar(text: $text)
    }
}
