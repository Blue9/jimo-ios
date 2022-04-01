//
//  PhoneNumberTextFieldView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/2/21.
//

import SwiftUI
import UIKit
import PhoneNumberKit

struct PhoneNumberTextFieldView: UIViewRepresentable {
    @Binding var phoneNumber: String
    private let textField = PhoneNumberTextField()
    
    func makeUIView(context: Context) -> PhoneNumberTextField {
        textField.withExamplePlaceholder = true
        textField.withFlag = true
        textField.withPrefix = true
        textField.withExamplePlaceholder = true
        textField.becomeFirstResponder()
        textField.addTarget(context.coordinator, action: #selector(Coordinator.onTextUpdate), for: .editingChanged)
        return textField
    }
    
    func updateUIView(_ view: PhoneNumberTextField, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PhoneNumberTextFieldView
        
        init(_ parent: PhoneNumberTextFieldView) {
            self.parent = parent
        }
        
        @objc func onTextUpdate(textField: UITextField) {
            self.parent.phoneNumber = textField.text!
        }
    }
}
