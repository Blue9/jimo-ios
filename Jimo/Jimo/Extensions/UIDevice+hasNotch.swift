//
//  UIDevice+hasNotch.swift
//  Jimo
//
//  Created by Gautam Mekkat on 9/15/21.
//

import UIKit

extension UIDevice {
    var hasNotch: Bool {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              window.safeAreaInsets.bottom >= 10 else {
            return false
        }
        return true
    }
}
