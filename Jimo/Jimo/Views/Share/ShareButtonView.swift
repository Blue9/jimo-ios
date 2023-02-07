//
//  ShareButtonView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/5/22.
//

import SwiftUI

struct ShareButtonView: View {
    @EnvironmentObject var appState: AppState
    var shareAction: ShareAction
    var size: CGFloat = 25

    @State private var isPresented = false

    var body: some View {
        Button {
            self.isPresented = true
        } label: {
            Group {
                if isPresented {
                    ProgressView()
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                }
            }
            .scaledToFit()
            .frame(width: size, height: size)
        }.sheet(isPresented: $isPresented) {
            ActivityView(shareAction: shareAction, isPresented: $isPresented)
        }
    }
}

enum ShareAction: Identifiable, Equatable {
    case profile(User), post(Post)

    var id: String {
        switch self {
        case .profile(let user):
            return user.id
        case .post(let post):
            return post.id
        }
    }

    var url: URL {
        switch self {
        case .profile(let user):
            return user.profileUrl
        case .post(let post):
            return post.postUrl
        }
    }

    var name: String {
        switch self {
        case .profile(let user):
            return user.username
        case .post(let post):
            return post.place.name
        }
    }

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

    static func == (lhs: ShareAction, rhs: ShareAction) -> Bool {
        lhs.id == rhs.id
    }
}
