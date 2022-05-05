//
//  ActivityView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/5/22.
//  https://stackoverflow.com/a/61102934

import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    var shareAction: ShareAction
    var applicationActivities: [UIActivity]? = nil
    
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> ActivityViewWrapper {
        ActivityViewWrapper(
            shareAction: shareAction,
            applicationActivities: applicationActivities,
            isPresented: $isPresented
        )
    }
    
    func updateUIViewController(_ uiViewController: ActivityViewWrapper, context: Context) {
        uiViewController.isPresented = $isPresented
        uiViewController.updateState()
    }
}

class ActivityViewWrapper: UIViewController, UIActivityItemSource {
    var shareAction: ShareAction
    var applicationActivities: [UIActivity]?
    
    var isPresented: Binding<Bool>
    
    var shareTitle: String {
        "Check \(shareAction.name) out on Jimo"
    }
    
    init(
        shareAction: ShareAction,
        applicationActivities: [UIActivity]? = nil,
        isPresented: Binding<Bool>
    ) {
        self.shareAction = shareAction
        self.applicationActivities = applicationActivities
        self.isPresented = isPresented
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        updateState()
    }
    
    fileprivate func updateState() {
        guard parent != nil else { return }
        let isActivityPresented = presentedViewController != nil
        if isActivityPresented != isPresented.wrappedValue {
            if !isActivityPresented {
                Analytics.track(shareAction.presentedEvent)
                let controller = UIActivityViewController(activityItems: [self], applicationActivities: applicationActivities)
                controller.completionWithItemsHandler = { (activityType, completed, _, _) in
                    if completed {
                        Analytics.track(self.shareAction.completedEvent, parameters: ["activity_type": activityType?.rawValue])
                    } else {
                        Analytics.track(self.shareAction.cancelledEvent)
                    }
                    self.isPresented.wrappedValue = false
                }
                self.present(controller, animated: true, completion: nil)
            }
            else {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return shareTitle
    }
    
    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        if activityType == .message {
            /// iMessage is stripping the query params from the URL for some reason
            /// https://developer.apple.com/forums/thread/131930
            return "\(shareTitle)\n\(shareAction.url.absoluteString)"
        }
        return shareAction.url
    }
}
