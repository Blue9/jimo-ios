//
//  PopupView.swift
//  PopupView
//
//  Created by Alisa Mylnikova on 23/04/2020.
//  Copyright © 2020 Exyte. All rights reserved.
//  From https://github.com/exyte/PopupView/blob/master/Source/PopupView.swift
//

import SwiftUI

extension View {

    public func popup<PopupContent: View>(
        isPresented: Binding<Bool>,
        type: Popup<PopupContent>.PopupType = .`default`,
        position: Popup<PopupContent>.Position = .bottom,
        animation: Animation = Animation.easeOut(duration: 0.3),
        autohideIn: Double? = nil,
        closeOnTap: Bool = true,
        closeOnTapOutside: Bool = true, // Originally false
        view: @escaping () -> PopupContent) -> some View {
        self.modifier(
            Popup(
                isPresented: isPresented,
                type: type,
                position: position,
                animation: animation,
                autohideIn: autohideIn,
                closeOnTap: closeOnTap,
                closeOnTapOutside: closeOnTapOutside,
                view: view)
        )
    }

    @ViewBuilder
    func applyIf<T: View>(_ condition: Bool, apply: (Self) -> T) -> some View {
        if condition {
            apply(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func addTapIfNotTV(if condition: Bool, onTap: @escaping ()->()) -> some View {
        #if os(tvOS)
        self
        #else
        if condition {
            self.simultaneousGesture(
                TapGesture().onEnded {
                    onTap()
                }
            )
        } else {
            self
        }
        #endif
    }

}

public struct Popup<PopupContent>: ViewModifier where PopupContent: View {

    public enum PopupType {

        case `default`
        case toast
        case floater(verticalPadding: CGFloat = 50)

        func shouldBeCentered() -> Bool {
            switch self {
            case .`default`:
                return true
            default:
                return false
            }
        }
    }

    public enum Position {

        case top
        case bottom
    }

    // MARK: - Public Properties

    /// Tells if the sheet should be presented or not
    @Binding var isPresented: Bool

    var type: PopupType
    var position: Position

    var animation: Animation

    /// If nil - niver hides on its own
    var autohideIn: Double?

    /// Should close on tap - default is `true`
    var closeOnTap: Bool

    /// Should close on tap outside - default is `true`
    var closeOnTapOutside: Bool

    var view: () -> PopupContent

    /// holder for autohiding dispatch work (to be able to cancel it when needed)
    var dispatchWorkHolder = DispatchWorkHolder()

    // MARK: - Private Properties

    /// The rect of the hosting controller
    @State private var presenterContentRect: CGRect = .zero

    /// The rect of popup content
    @State private var sheetContentRect: CGRect = .zero

    /// The offset when the popup is displayed
    private var displayedOffset: CGFloat {
        switch type {
        case .`default`:
            return  -presenterContentRect.midY + screenHeight/2
        case .toast:
            if position == .bottom {
                return screenHeight - presenterContentRect.midY - sheetContentRect.height/2
            } else {
                return -presenterContentRect.midY + sheetContentRect.height/2
            }
        case .floater(let verticalPadding):
            if position == .bottom {
                return screenHeight - presenterContentRect.midY - sheetContentRect.height/2 - verticalPadding
            } else {
                return -presenterContentRect.midY + sheetContentRect.height/2 + verticalPadding
            }
        }
    }

    /// The offset when the popup is hidden
    private var hiddenOffset: CGFloat {
        if position == .top {
            if presenterContentRect.isEmpty {
                return -1000
            }
            return -presenterContentRect.midY - sheetContentRect.height/2 - 5
        } else {
            if presenterContentRect.isEmpty {
                return 1000
            }
            return screenHeight - presenterContentRect.midY + sheetContentRect.height/2 + 5
        }
    }

    /// The current offset, based on the **presented** property
    private var currentOffset: CGFloat {
        return isPresented ? displayedOffset : hiddenOffset
    }

    private var screenSize: CGSize {
        #if os(iOS) || os(tvOS)
        return UIScreen.main.bounds.size
        #elseif os(watchOS)
        return WKInterfaceDevice.current().screenBounds.size
        #else
        return NSScreen.main?.frame.size ?? .zero
        #endif
    }

    private var screenHeight: CGFloat {
        screenSize.height
    }

    // MARK: - Content Builders

    public func body(content: Content) -> some View {
        content
            .addTapIfNotTV(if: closeOnTapOutside) {
                self.dispatchWorkHolder.work?.cancel()
                self.isPresented = false
            }
            .background(
                GeometryReader { proxy -> AnyView in
                    let rect = proxy.frame(in: .global)
                    // This avoids an infinite layout loop
                    if rect.integral != self.presenterContentRect.integral {
                        DispatchQueue.main.async {
                            self.presenterContentRect = rect
                        }
                    }
                    return AnyView(EmptyView())
                }
            ).overlay(sheet())
    }

    /// This is the builder for the sheet content
    func sheet() -> some View {

        // if needed, dispatch autohide and cancel previous one
        if let autohideIn = autohideIn {
            dispatchWorkHolder.work?.cancel()
            dispatchWorkHolder.work = DispatchWorkItem(block: {
                self.isPresented = false
            })
            if isPresented, let work = dispatchWorkHolder.work {
                DispatchQueue.main.asyncAfter(deadline: .now() + autohideIn, execute: work)
            }
        }

        return ZStack {
            Group {
                VStack {
                    VStack {
                        self.view()
                            .addTapIfNotTV(if: closeOnTap) {
                                self.dispatchWorkHolder.work?.cancel()
                                self.isPresented = false
                            }
                            .background(
                                GeometryReader { proxy -> AnyView in
                                    let rect = proxy.frame(in: .global)
                                    // This avoids an infinite layout loop
                                    if rect.integral != self.sheetContentRect.integral {
                                        DispatchQueue.main.async {
                                            self.sheetContentRect = rect
                                        }
                                    }
                                    return AnyView(EmptyView())
                                }
                            )
                    }
                }
                .frame(width: screenSize.width)
                .offset(x: 0, y: currentOffset)
                .animation(animation)
            }
        }
    }
}

class DispatchWorkHolder {
    var work: DispatchWorkItem?
}
