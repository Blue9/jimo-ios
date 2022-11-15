//
//  UIDevice+hasNotch.swift
//  Jimo
//
//  Created by Gautam Mekkat on 9/15/21.
//

import UIKit

extension UIDevice {
    var hasNotch: Bool {
        if #available(iOS 11.0, tvOS 11.0, *) {
            return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
        }
        return false
    }
}
