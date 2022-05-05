//
//  ActivityView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/5/22.
//  https://stackoverflow.com/a/61102934

import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    var shareType: ShareType
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> ActivityViewWrapper {
        ActivityViewWrapper(
            shareType: shareType,
            activityItems: activityItems,
            applicationActivities: applicationActivities,
            isPresented: $isPresented
        )
    }
    
    func updateUIViewController(_ uiViewController: ActivityViewWrapper, context: Context) {
        uiViewController.isPresented = $isPresented
        uiViewController.updateState()
    }
}

class ActivityViewWrapper: UIViewController {
    var shareType: ShareType
    var activityItems: [Any]
    var applicationActivities: [UIActivity]?
    
    var isPresented: Binding<Bool>
    
    init(
        shareType: ShareType,
        activityItems: [Any],
        applicationActivities: [UIActivity]? = nil,
        isPresented: Binding<Bool>
    ) {
        self.shareType = shareType
        self.activityItems = activityItems
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
                Analytics.track(shareType.presentedEvent)
                let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
                controller.completionWithItemsHandler = { (activityType, completed, _, _) in
                    if completed {
                        Analytics.track(self.shareType.completedEvent, parameters: ["activity_type": activityType?.rawValue])
                    } else {
                        Analytics.track(self.shareType.cancelledEvent)
                    }
                    self.isPresented.wrappedValue = false
                }
                present(controller, animated: true, completion: nil)
            }
            else {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}
