//
//  UINavigationController+UIGestureRecognizerDelegate.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/5/21.
//

import UIKit

// This allows us to swipe back even when the navigation bar is hidden
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
