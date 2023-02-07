//
//  LocationPingService.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/7/23.
//

import FirebaseRemoteConfig
import Combine

class LocationPingService {
    var locationPingTimer: Timer?
    var locationPingCancellable: AnyCancellable?
    var apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func invalidate() {
        self.locationPingTimer?.invalidate()
    }

    func locationPingBackground() {
        self.locationPingTimer?.invalidate()
        let pingConfig = RemoteConfig.remoteConfig().configValue(forKey: "locationPingInterval").numberValue.doubleValue
        let pingInterval = pingConfig == 0 ? 120.0 : pingConfig
        let timer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] timer in
            guard let location = PermissionManager.shared.locationManager.location else {
                return
            }
            guard let self = self else {
                timer.invalidate()
                return
            }
            let pingConfig = RemoteConfig.remoteConfig().configValue(forKey: "locationPingInterval").numberValue.doubleValue
            let pingInterval = pingConfig == 0 ? 60.0 : pingConfig
            if pingInterval != timer.timeInterval {
                print("Refreshing location ping timer")
                self.locationPingBackground()
            }
            print("Pinging location")
            self.locationPingCancellable = self.apiClient.pingLocation(Location(coord: location.coordinate))
                .sink(receiveCompletion: {_ in}, receiveValue: {_ in})
        }
        timer.tolerance = 2
        RunLoop.current.add(timer, forMode: .common)
        self.locationPingTimer = timer
    }
}
