//
//  NetworkConnectionMonitor.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/31/22.
//

import SwiftUI
import Combine
import Network

class NetworkConnectionMonitor: ObservableObject {
    let monitor = NWPathMonitor()
    var cancelBag: Set<AnyCancellable> = Set()

    @Published var connected = true

    func listen() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                if path.status != .satisfied {
                    self.connected = false
                } else {
                    self.connected = true
                }
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
}
