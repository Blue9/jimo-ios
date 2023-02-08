//
//  FormInputText.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/6/23.
//

import SwiftUI

struct FormInputText: View {
    var name: String
    var height: CGFloat = 100
    @Binding var text: String

    var body: some View {
        if #available(iOS 15.0, *) {
            MultilineTextField(name, text: $text, height: height)
                .font(.system(size: 15))
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()

                        Button("Done") {
                            hideKeyboard()
                        }
                        .foregroundColor(.blue)
                    }
                }
        } else {
            MultilineTextField(name, text: $text, height: height)
                .font(.system(size: 15))
        }
    }
}