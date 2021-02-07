
import Foundation
import SwiftUI

public struct BlurView: UIViewRepresentable {
    public func makeUIView(context: UIViewRepresentableContext<BlurView>) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: context.environment.colorScheme == .dark ? .dark : .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView, at: 0)

        NSLayoutConstraint.activate([
            blurView.heightAnchor.constraint(equalTo: view.heightAnchor),
            blurView.widthAnchor.constraint(equalTo: view.widthAnchor),
            blurView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            blurView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        return view
    }

    public func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<BlurView>) {
        guard let effectView = uiView.subviews.first as? UIVisualEffectView else { return }
        let blurEffect = UIBlurEffect(style: context.environment.colorScheme == .dark ? .dark : .light)
        effectView.effect = blurEffect

    }
}
