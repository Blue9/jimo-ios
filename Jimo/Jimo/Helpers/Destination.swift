//
//  Destination.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/31/23.
//

import SwiftUI

protocol NavigationDestinationEnum: Hashable {
    associatedtype Content: View
    func view() -> Content
}
