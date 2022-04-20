//
//  DeepLinkManager.swift
//  Jimo
//
//  Created by Xilin Liu on 4/20/22.
//

import Foundation

class DeepLinkManager: ObservableObject {
    @Published var presentableEntity: DeepLinkEntity = .none
}

fileprivate let gcmMessageIDKey = "gcm.message_id"

fileprivate let appState = AppState(apiClient: APIClient())
fileprivate let globalViewState = GlobalViewState()
fileprivate let deepLinkManager = DeepLinkManager()
