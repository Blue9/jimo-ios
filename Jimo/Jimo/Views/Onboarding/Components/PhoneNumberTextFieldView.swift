//
//  PhoneNumberTextFieldView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/2/21.
//

import SwiftUI
import UIKit
import PhoneNumberKit

enum JimoPhoneNumberInput: Equatable {
    case number(PhoneNumber)
    case secretMenu
}

struct PhoneNumberTextFieldView: UIViewRepresentable {
    @Binding var phoneNumber: JimoPhoneNumberInput?
    private let textField = PhoneNumberTextField()

    func makeUIView(context: Context) -> PhoneNumberTextField {
        textField.placeholder = "(845) 462-5555"
        textField.withDefaultPickerUI = true
        textField.withFlag = true
        textField.withPrefix = true
        textField.textContentType = .telephoneNumber
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
            if let phoneNumber = parent.textField.phoneNumber {
                self.parent.phoneNumber = .number(phoneNumber)
            } else if textField.text == "546-6" {
                /// Hack to allow logging in with emails
                self.parent.phoneNumber = .secretMenu
            }
        }
    }
}
