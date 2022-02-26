//
//  UIKitTabView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/19/21.
//  From https://gist.github.com/Amzd/2eb5b941865e8c5cccf149e6e07c8810

import SwiftUI

/// This allows us to pop to root and scroll to the top when tapping a tab twice
public struct UIKitTabView: View {
    private var viewControllers: [UIHostingController<AnyView>]
    private var selectedIndex: Binding<Int>?
    @State private var fallbackSelectedIndex: Int = 0
    
    public init(selectedIndex: Binding<Int>? = nil, @TabBuilder _ views: () -> [Tab]) {
        self.viewControllers = views().map {
            let host = UIHostingController(rootView: $0.view)
            host.tabBarItem = $0.barItem
            if UIDevice.current.hasNotch {
                host.tabBarItem.imageInsets = UIEdgeInsets(top: 4, left: 2, bottom: 0, right: 2)
            } else {
                host.tabBarItem.imageInsets = UIEdgeInsets(top: 3, left: 2, bottom: 1, right: 2)
            }
            return host
        }
        self.selectedIndex = selectedIndex
    }
    
    public var body: some View {
        TabBarController(controllers: viewControllers, selectedIndex: selectedIndex ?? $fallbackSelectedIndex)
            .edgesIgnoringSafeArea(.all)
    }
    
    public struct Tab {
        var view: AnyView
        var barItem: UITabBarItem
    }
}

@resultBuilder
public struct TabBuilder {
    public static func buildBlock(_ items: UIKitTabView.Tab...) -> [UIKitTabView.Tab] {
        items
    }
}

extension View {
    public func tab(title: String, image: String? = nil, selectedImage: String? = nil, badgeValue: String? = nil) -> UIKitTabView.Tab {
        func imageOrSystemImage(named: String?) -> UIImage? {
            guard let name = named else { return nil }
            return UIImage(named: name) ?? UIImage(systemName: name)
        }
        
        let image = imageOrSystemImage(named: image)
        let selectedImage = imageOrSystemImage(named: selectedImage)
        let barItem = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
        
        barItem.badgeValue = badgeValue
        
        return UIKitTabView.Tab(view: AnyView(self), barItem: barItem)
    }
}

fileprivate struct TabBarController: UIViewControllerRepresentable {
    var controllers: [UIViewController]
    @Binding var selectedIndex: Int
    
    func makeUIViewController(context: Context) -> UITabBarController {
        let tabBarController = UITabBarController()
        tabBarController.tabBar.clipsToBounds = false
        tabBarController.viewControllers = controllers
        tabBarController.delegate = context.coordinator
        tabBarController.selectedIndex = 0
        return tabBarController
    }
    
    func updateUIViewController(_ tabBarController: UITabBarController, context: Context) {
        tabBarController.selectedIndex = selectedIndex
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITabBarControllerDelegate {
        var parent: TabBarController
        
        init(_ tabBarController: TabBarController) {
            self.parent = tabBarController
        }
        
        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            if parent.selectedIndex == tabBarController.selectedIndex {
                popToRootOrScrollUp(on: viewController)
            }
            
            parent.selectedIndex = tabBarController.selectedIndex
        }
        
        private func popToRootOrScrollUp(on viewController: UIViewController) {
            let nvc = navigationController(for: viewController)
            let popped = nvc?.popToRootViewController(animated: true)
            
            if (popped ?? []).isEmpty {
                let rootViewController = nvc?.viewControllers.first ?? viewController
                if let scrollView = firstScrollView(in: rootViewController.view ?? UIView()) {
                    let preservedX = scrollView.contentOffset.x
                    let y = -scrollView.adjustedContentInset.top
                    scrollView.setContentOffset(CGPoint(x: preservedX, y: y), animated: true)
                }
            }
        }
        
        private func navigationController(for viewController: UIViewController) -> UINavigationController? {
            for child in viewController.children {
                if let nvc = viewController as? UINavigationController {
                    return nvc
                } else if let nvc = navigationController(for: child) {
                    return nvc
                }
            }
            return nil
        }
        
        public func firstScrollView(in view: UIView) -> UIScrollView? {
            for subview in view.subviews {
                if let scrollView = view as? UIScrollView {
                    return scrollView
                } else if let scrollView = firstScrollView(in: subview) {
                    return scrollView
                }
            }
            return nil
        }
    }
}
