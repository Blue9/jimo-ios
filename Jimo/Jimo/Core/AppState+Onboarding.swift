//
//  AppState+Onboarding.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/11/23.
//

import Combine

extension AppState {
    // MARK: - Onboarding routes
    func getOnboardingCities() -> AnyPublisher<[String], APIError> {
        apiClient.getOnboardingCities()
    }

    func getOnboardingPlaces(for city: String) -> AnyPublisher<PlaceTilePage, APIError> {
        apiClient.getOnboardingPlaces(for: city)
    }

    func submitOnboardingPlaces(
        city: String?,
        posts: [MinimalCreatePostRequest],
        saves: [MinimalSavePlaceRequest]
    ) -> AnyPublisher<SimpleResponse, APIError> {
        apiClient.submitOnboardingPlaces(
            OnboardingCreateMultiRequest(
                city: city,
                posts: posts,
                saves: saves
            )
        )
    }
}
