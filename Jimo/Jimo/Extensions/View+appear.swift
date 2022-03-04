//
//  View+appear.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/27/21.
//

import SwiftUI
import FirebaseAnalytics

// onAppear and onDisappear are buggy, this is a more stable way of handling onAppear and onDisappear events.
struct UIKitAppear: UIViewControllerRepresentable {
    let action: () -> Void
    
    func makeUIViewController(context: Context) -> UIAppearViewController {
       let vc = UIAppearViewController()
        vc.action = action

        return vc
    }
    
    func updateUIViewController(_ controller: UIAppearViewController, context: Context) {
    }
}

class UIAppearViewController: UIViewController {
    var action: (() -> Void)?
    
    override func viewDidLoad() {
        view.addSubview(UILabel())
    }
    
    override func viewDidAppear(_ animated: Bool) {

        action?()
    }
}

extension View {
    func appear(_ perform: @escaping () -> Void) -> some View {
        self.background(UIKitAppear(action: perform))
    }
}
