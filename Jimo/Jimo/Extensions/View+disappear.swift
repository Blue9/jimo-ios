//
//  View+disappear.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/27/21.
//

import SwiftUI

// onAppear and onDisappear are buggy, this is a more stable way of handling onAppear and onDisappear events.
struct UIKitDisappear: UIViewControllerRepresentable {
    let action: () -> Void
    
    func makeUIViewController(context: Context) -> UIDisappearViewController {
       let vc = UIDisappearViewController()
        vc.action = action
        return vc
    }
    
    func updateUIViewController(_ controller: UIDisappearViewController, context: Context) {
    }
}

class UIDisappearViewController: UIViewController {
    var action: (() -> Void)?
    
    override func viewDidLoad() {
        view.addSubview(UILabel())
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        action?()
    }
}

extension View {
    func disappear(_ perform: @escaping () -> Void) -> some View {
        self.background(UIKitDisappear(action: perform))
    }
}
