//
//  ShareButtonView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/5/22.
//

import SwiftUI

struct ShareButtonView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @State private var showShareSheet = false
    var shareType: ShareType
    var url: URL
    var size: CGFloat = 25
    
    var body: some View {
        Button {
            showShareSheet = true
        } label: {
            Group {
                if showShareSheet {
                    ProgressView()
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                }
            }
            .scaledToFit()
            .frame(width: size, height: size)
        }
        .background(ActivityView(
            shareType: shareType,
            activityItems: [url],
            applicationActivities: nil,
            isPresented: $showShareSheet
        ))
    }
}

enum ShareType: Equatable {
    case profile, post
    
    var presentedEvent: AnalyticsName {
        switch self {
        case .profile:
            return .shareProfilePresented
        case .post:
            return .sharePostPresented
        }
    }
    
    var completedEvent: AnalyticsName {
        switch self {
        case .profile:
            return .shareProfileCompleted
        case .post:
            return .sharePostCompleted
        }
    }
    
    var cancelledEvent: AnalyticsName {
        switch self {
        case .profile:
            return .shareProfileCancelled
        case .post:
            return .sharePostCancelled
        }
    }
}
