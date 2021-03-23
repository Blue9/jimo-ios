//
//  RefreshableScrollView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/18/21.
//

import SwiftUI

typealias OnFinish = () -> Void
typealias OnRefresh = (@escaping OnFinish) -> Void
typealias OnLoadMore = () -> Void

class RefreshableScrollViewController<Content: View>: UIViewController {
    var scrollView: UIScrollView
    
    var hostingController: UIHostingController<Content>
    
    init(scrollView: UIScrollView, content: Content) {
        self.hostingController = UIHostingController(rootView: content)
        self.scrollView = scrollView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override func loadView() {
        self.view = scrollView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        fillView(view: hostingController.view, viewToFill: view)
    }
    
    func update(view: Content) {
        hostingController.rootView = view
    }
    
    private func fillView(view: UIView, viewToFill: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            view.leadingAnchor.constraint(equalTo: viewToFill.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: viewToFill.trailingAnchor),
            view.topAnchor.constraint(equalTo: viewToFill.topAnchor),
            view.bottomAnchor.constraint(equalTo: viewToFill.bottomAnchor),
            view.widthAnchor.constraint(equalTo: viewToFill.widthAnchor)
        ]
        viewToFill.addConstraints(constraints)
    }
}

struct RefreshableScrollView<Content: View>: UIViewControllerRepresentable {
    typealias UIViewControllerType = RefreshableScrollViewController<Content>
    
    var content: Content
    var onRefresh: OnRefresh
    var onLoadMore: OnLoadMore?
    
    init(
        @ViewBuilder content: () -> Content,
        onRefresh: @escaping OnRefresh,
        onLoadMore: OnLoadMore? = nil
    ) {
        self.content = content()
        self.onRefresh = onRefresh
        self.onLoadMore = onLoadMore
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onRefresh: onRefresh, onLoadMore: onLoadMore)
    }
    
    func makeUIViewController(context: Context) -> RefreshableScrollViewController<Content> {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        let refreshControl = UIRefreshControl()
        scrollView.refreshControl = refreshControl
        scrollView.addSubview(refreshControl)
        refreshControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefreshControl),
            for: .valueChanged
        )
        refreshControl.setRandomRefreshColor()
        refreshControl.backgroundColor = .clear
        return RefreshableScrollViewController(scrollView: scrollView, content: content)
    }
    
    func updateUIViewController(_ controller: RefreshableScrollViewController<Content>, context: Context) {
        controller.update(view: content)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: RefreshableScrollView
        var onRefresh: OnRefresh
        var onLoadMore: OnLoadMore?
        
        /// If we call refreshControl.endRefreshing() while dragging, the scroll view jumps. This accounts for that
        var shouldEndRefreshLater = false
        var loadingMore = false
                
        init(_ parent: RefreshableScrollView, onRefresh: @escaping OnRefresh, onLoadMore: OnLoadMore?) {
            self.parent = parent
            self.onRefresh = onRefresh
            self.onLoadMore = onLoadMore
        }
        
        @objc func handleRefreshControl(sender: UIRefreshControl) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            let scrollView = sender.superview as? UIScrollView
            onRefresh { [weak self] in self?.endRefresh(scrollView, sender) }
        }
        
        func endRefresh(_ scrollView: UIScrollView?, _ refreshControl: UIRefreshControl?) {
            guard let scrollView = scrollView, let refreshControl = refreshControl else {
                return
            }
            if !refreshControl.isRefreshing {
                return
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if scrollView.isDragging {
                self.shouldEndRefreshLater = true
            } else {
                refreshControl.endRefreshing()
                refreshControl.setRandomRefreshColor()
            }
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if shouldEndRefreshLater {
                scrollView.refreshControl?.endRefreshing()
                scrollView.refreshControl?.setRandomRefreshColor()
                scrollView.setContentOffset(.zero, animated: true)
                shouldEndRefreshLater = false
            }
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // Load more logic
            let atBottom = scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.size.height
            if atBottom && !loadingMore {
                loadingMore = true
                onLoadMore?()
            }
            if !atBottom {
                loadingMore = false
            }
        }
    }
}

fileprivate extension UIRefreshControl {
    func setRandomRefreshColor() {
        guard let color = Colors.colors.randomElement() else {
            return
        }
        // The refresh control is a little dark by default so this makes it lighter
        func scaleColor(_ val: CGFloat, _ scale: CGFloat) -> CGFloat {
            max(0, min(val * scale, 1))
        }
        
        let baseColor = UIColor(color)
        let scale: CGFloat = 1.2
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        baseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let tintColor = UIColor(
            red: scaleColor(red, scale),
            green: scaleColor(green, scale),
            blue: scaleColor(blue, scale),
            alpha: alpha
        )
        self.tintColor = tintColor
    }

}
