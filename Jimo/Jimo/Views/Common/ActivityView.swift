//
//  ActivityView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/5/22.
//

import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    let shareAction: ShareAction
    var isPresented: Binding<Bool>

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        Analytics.track(shareAction.presentedEvent)
        let controller = UIActivityViewController(activityItems: [ActivityItemSource(shareAction)], applicationActivities: nil)
        controller.completionWithItemsHandler = { (activityType, completed, _, _) in
            if completed {
                Analytics.track(self.shareAction.completedEvent, parameters: ["activity_type": activityType?.rawValue])
            } else {
                Analytics.track(self.shareAction.cancelledEvent)
            }
            self.isPresented.wrappedValue = false
        }
        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: UIViewControllerRepresentableContext<ActivityView>
    ) {
    }
}

private class ActivityItemSource: NSObject, UIActivityItemSource {
    let shareAction: ShareAction

    var shareTitle: String {
        "Check \(shareAction.name) out on Jimo"
    }

    init(_ shareAction: ShareAction) {
        self.shareAction = shareAction
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
