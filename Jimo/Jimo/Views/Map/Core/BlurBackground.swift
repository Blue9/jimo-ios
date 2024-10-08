//
//  BlurBackground.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/11/23.
//

import SwiftUI

struct BlurBackground: UIViewRepresentable {
    var effect: UIVisualEffect

    func makeUIView(context: Context) -> UIVisualEffectView {
        let effectView = UIVisualEffectView(effect: self.effect)
        return effectView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = self.effect
    }
}
