//
//  MultilineTextInput.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI
import UIKit

// Mostly same as https://stackoverflow.com/a/58639072 with unneeded parts taken out
fileprivate struct UITextViewWrapper: UIViewRepresentable {
    @Binding var text: String
    var height: CGFloat
    
    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let textField = UITextView()
        textField.delegate = context.coordinator
        
        textField.isEditable = true
        textField.returnKeyType = .done
        textField.font = UIFont(name: Poppins.regular, size: 14)
        textField.textColor = .black
        textField.isSelectable = true
        textField.isUserInteractionEnabled = true
        textField.isScrollEnabled = true
        textField.backgroundColor = UIColor.clear
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }
    
    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<UITextViewWrapper>) {
        if uiView.text != self.text {
            uiView.text = self.text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, height: height)
    }
    
    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        var height: CGFloat
        
        init(text: Binding<String>, height: CGFloat) {
            self._text = text
            self.height = height
        }
        
        func textViewDidChange(_ uiView: UITextView) {
            text = uiView.text
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                textView.resignFirstResponder()
                hideKeyboard()
                return false
            }
            return true
        }
    }
}

struct MultilineTextField: View {
    private var placeholder: String
    private var height: CGFloat = 80
    @Binding private var text: String
    @State private var showingPlaceholder = false
    
    private var internalText: Binding<String> {
        Binding<String>(get: { self.text } ) {
            self.text = $0
            self.showingPlaceholder = $0.isEmpty
        }
    }
    
    init (_ placeholder: String = "", text: Binding<String>, height: CGFloat? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.height = height ?? self.height
        self._showingPlaceholder = State<Bool>(initialValue: self.text.isEmpty)
    }
    
    var body: some View {
        UITextViewWrapper(text: self.internalText, height: height)
            .frame(minHeight: height, maxHeight: height)
            .background(placeholderView, alignment: .topLeading)
    }
    
    var placeholderView: some View {
        Group {
            if showingPlaceholder {
                Text(placeholder)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .padding(.leading, 4)
                    .padding(.top, 8)
            }
        }
    }
}

struct MultilineTextField_Previews: PreviewProvider {
    static var test: String = ""
    static var testBinding = Binding<String>(get: { test }, set: { test = $0 } )
    
    static var previews: some View {
        VStack(alignment: .leading) {
            Text("Description:")
            MultilineTextField("Enter some text here", text: testBinding)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black))
            Text("Something static here...")
            Spacer()
        }
        .padding()
    }
}
