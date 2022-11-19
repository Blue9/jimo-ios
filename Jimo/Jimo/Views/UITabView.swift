//
//  UITabView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/19/21.
//  From https://gist.github.com/Amzd/2eb5b941865e8c5cccf149e6e07c8810?permalink_comment_id=3738662#gistcomment-3738662

import SwiftUI

/// This allows us to pop to root and scroll to the top when tapping a tab twice
struct UITabView: View {
    private let viewControllers: [UIHostingController<AnyView>]
    private let tabBarItems: [TabBarItem]
    @Binding private var selectedIndex: Int
    
    init(selection: Binding<Int>, @TabBuilder _ content: () -> [TabBarItem]) {
        _selectedIndex = selection
        
        (viewControllers, tabBarItems) = content().reduce(into: ([], [])) { result, next in
            let tabController = UIHostingController(rootView: next.view)
            tabController.tabBarItem = next.barItem
            if UIDevice.current.hasNotch {
                tabController.tabBarItem.imageInsets = UIEdgeInsets(top: 3, left: 0, bottom: -1, right: 0)
            }
            result.0.append(tabController)
            result.1.append(next)
        }
    }
    
    var body: some View {
        TabBarController(
            controllers: viewControllers,
            tabBarItems: tabBarItems,
            selectedIndex: $selectedIndex
        ).ignoresSafeArea(.all, edges: .top)
    }
}

extension UITabView {
    struct TabBarItem {
        let view: AnyView
        let barItem: UITabBarItem
        let badgeValue: String?
        
        init<T>(
            title: String,
            image: UIImage?,
            selectedImage: UIImage? = nil,
            badgeValue: String? = nil,
            content: T
        ) where T: View {
            self.view = AnyView(content)
            self.barItem = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
            self.badgeValue = badgeValue
        }
    }
    
    struct TabBarController: UIViewControllerRepresentable {
        let controllers: [UIViewController]
        let tabBarItems: [TabBarItem]
        @Binding var selectedIndex: Int
        
        func makeUIViewController(context: Context) -> UITabBarController {
            let tabBarController = UITabBarController()
            tabBarController.viewControllers = controllers
            tabBarController.delegate = context.coordinator
            tabBarController.selectedIndex = selectedIndex
            return tabBarController
        }
        
        func updateUIViewController(_ tabBarController: UITabBarController, context: Context) {
            tabBarController.selectedIndex = selectedIndex
            
            tabBarItems.forEach { tab in
                guard let index = tabBarItems.firstIndex(where: { $0.barItem == tab.barItem }),
                      let controllers = tabBarController.viewControllers
                else {
                    return
                }
                
                guard controllers.indices.contains(index) else { return }
                controllers[index].tabBarItem.badgeValue = tab.badgeValue
            }
        }
        
        func makeCoordinator() -> TabBarCoordinator {
            TabBarCoordinator(self)
        }
    }
    
    class TabBarCoordinator: NSObject, UITabBarControllerDelegate {
        private static let inlineTitleRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        private var parent: TabBarController
        
        init(_ tabBarController: TabBarController) {
            self.parent = tabBarController
        }
        
        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            if parent.selectedIndex == tabBarController.selectedIndex {
                if let navigationController = navigationController(in: viewController) {
                    let numPopped = navigationController.popToRootViewController(animated: true)?.count ?? 0
                    let didPop = numPopped > 0
                    if !didPop {
                        scrollToTop(in: viewController)
                    }
                }
            }
            parent.selectedIndex = tabBarController.selectedIndex
        }
        
        func scrollToTop(in viewController: UIViewController) {
            guard let scrollView = scrollView(in: viewController.view) else { return }
            scrollView.scrollRectToVisible(Self.inlineTitleRect, animated: true)
        }
        
        func scrollView(in view: UIView) -> UIScrollView? {
            if let collectionView = view as? UICollectionView {
                // Hack to handle paging tab view in feed tab
                let feedIndex = collectionView.indexPathsForVisibleItems.first?.last
                if let index = feedIndex, collectionView.subviews.count > index {
                    return scrollView(in: collectionView.subviews[index])
                }
            }
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            for subview in view.subviews {
                if let scrollView = scrollView(in: subview) {
                    return scrollView
                }
            }
            return nil
        }
        
        func navigationController(in viewController: UIViewController) -> UINavigationController? {
            var controller: UINavigationController?
            if let navigationController = viewController as? UINavigationController {
                return navigationController
            }
            viewController.children.forEach {
                guard let navigationController = $0 as? UINavigationController else {
                    controller = navigationController(in: $0)
                    return
                }
                controller = navigationController
            }
            return controller
        }
    }
}

extension View {
    func tabItem(
        _ title: String,
        image: UIImage?,
        selectedImage: UIImage? = nil,
        badgeValue: String? = nil
    ) -> UITabView.TabBarItem {
        UITabView.TabBarItem(
            title: title,
            image: image,
            selectedImage: selectedImage,
            badgeValue: badgeValue,
            content: self
        )
    }
}

fileprivate extension UIView {
    var viewController: UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.viewController
        } else {
            return nil
        }
    }
}

@resultBuilder
struct TabBuilder {
    static func buildBlock(_ elements: UITabView.TabBarItem...) -> [UITabView.TabBarItem] {
        elements
    }
}
