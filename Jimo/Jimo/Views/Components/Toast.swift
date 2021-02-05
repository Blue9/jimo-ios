//
//  Toast.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/28/20.
//

import SwiftUI

enum ToastType {
    case success, warning, error;
    
    func color() -> Color {
        switch (self) {
        case .success:
            return Color(red: 0.15, green: 0.83, blue: 0.3)
        case .warning:
            return Color(red: 1, green: 0.7, blue: 0)
        case .error:
            return Color(red: 0.85, green: 0.2, blue: 0.15)
        }
    }
}

struct Toast: View {
    
    let text: String
    let type: ToastType
    
    var body: some View {
        Text(text)
            .font(Font.custom(Poppins.medium, size: 14))
            .foregroundColor(.white)
            .padding(15)
            .background(type.color())
            .cornerRadius(15)
            .padding(.bottom, 40)
            .shadow(radius: 5)
    }
}
