//
//  APIClient+Onboarding.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/10/23.
//

import Combine
import Foundation

extension Endpoint {
    static func getOnboardingCities() -> Endpoint {
        .init(path: "/onboarding/cities")
    }

    static func onboardingPlaces(city: String? = nil) -> Endpoint {
        .init(
            path: "/onboarding/places",
            queryItems: city != nil ? [URLQueryItem(name: "city", value: city!)] : []
        )
    }
}

extension APIClient {
    func getOnboardingCities() -> AnyPublisher<[String], APIError> {
        doRequest(endpoint: .getOnboardingCities())
    }

    func getOnboardingPlaces(for city: String) -> AnyPublisher<PlaceTilePage, APIError> {
        doRequest(endpoint: .onboardingPlaces(city: city))
    }

    func submitOnboardingPlaces(_ request: OnboardingCreateMultiRequest) -> AnyPublisher<SimpleResponse, APIError> {
        doRequest(endpoint: .onboardingPlaces(), httpMethod: "POST", body: request)
    }
}
