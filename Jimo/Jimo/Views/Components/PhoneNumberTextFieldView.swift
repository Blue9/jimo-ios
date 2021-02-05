//
//  PhoneNumberTextFieldView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/2/21.
//

import SwiftUI
import PhoneNumberKit

struct PhoneNumberTextFieldView: UIViewRepresentable {
    private let textField = PhoneNumberTextField()
    
    func makeUIView(context: Context) -> PhoneNumberTextField {
        textField.withFlag = true
        textField.withPrefix = true
        textField.withExamplePlaceholder = true
        return textField
    }
    
    func getPhoneNumber() -> PhoneNumber? {
        return textField.phoneNumber
    }
    
    func updateUIView(_ view: PhoneNumberTextField, context: Context) {
    
    }
}

struct PhoneNumberTextFieldView_Previews: PreviewProvider {    
    static var previews: some View {
        PhoneNumberTextFieldView()
    }
}
