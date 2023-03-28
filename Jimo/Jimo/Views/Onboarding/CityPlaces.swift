//
//  CityPlaces.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/11/23.
//

import SwiftUI
import SwiftUIPager

struct CityPlaces: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ViewModel()
    @State private var showWarning = false

    let city: String
    let done: () -> Void

    var body: some View {
        VStack {
            switch viewModel.loadStatus {
            case .loading:
                ProgressView()
                    .task {
                        await viewModel.load(city: city, appState: appState)
                    }
            case .error:
                VStack {
                    Text("Could not load places. Check your internet connection and try again.")
                        .font(.caption)
                    Button {
                        Task {
                            await viewModel.load(city: city, appState: appState)
                        }
                    } label: {
                        Text("Try again")
                            .foregroundColor(.blue)
                    }.disabled(viewModel.loadStatus == .loading)
                }
                .padding(.horizontal, 40)
            case .loaded(let places):
                LoadedCityPlaces(places: places, city: city, submit: submitPlaces)
            }
        }
        .alert(
            "Error",
            isPresented: $showWarning,
            presenting: viewModel.places,
            actions: { places in
                Button("Try again", action: { submitPlaces(places) })
                Button("Continue without saving", action: done)
                Button("Close", role: .cancel, action: {})
            },
            message: { _ in
                Text("Could not add places. Check your internet connection and try again.")
            }
        )
    }

    private func submitPlaces(_ places: [PlaceTileState]) {
        Task {
            await viewModel.submit(
                places: places,
                city: city,
                appState: appState,
                complete: { success in
                    if success {
                        done()
                    } else {
                        DispatchQueue.main.async {
                            showWarning = true
                        }
                    }
                }
            )
        }
    }
}

extension CityPlaces {
    fileprivate enum Status: Equatable {
        case loading, loaded([PlaceTileState]), error
    }

    fileprivate class ViewModel: ObservableObject {
        @Published var places: [PlaceTileState]?
        @Published var loadStatus = Status.loading

        @MainActor
        func load(city: String, appState: AppState) async {
            self.loadStatus = .loading
            do {
                for try await placeTilePage in appState.getOnboardingPlaces(
                    for: city
                ).values {
                    let places = placeTilePage.places.map({ PlaceTileState(tile: $0) })
                    self.places = places
                    self.loadStatus = .loaded(places)
                }
            } catch {
                self.loadStatus = .error
            }
        }

        @MainActor
        func submit(
            places: [PlaceTileState],
            city: String,
            appState: AppState,
            complete: (_ success: Bool) -> Void
        ) async {
            do {
                for try await responses in appState.submitOnboardingPlaces(
                    city: city,
                    posts: places.compactMap({
                        $0.post ?
                            .init(
                                placeId: $0.tile.placeId,
                                category: $0.tile.category,
                                stars: $0.stars
                            )
                        : nil
                    }),
                    saves: places.compactMap({
                        $0.saved ? .init(placeId: $0.tile.placeId) : nil
                    })
                ).values {
                    complete(responses.success)
                }
            } catch {
                complete(false)
            }
        }
    }
}

private struct PlaceTileState: Equatable {
    var tile: PlaceTile
    var post: Bool = false
    var stars: Int?
    var saved: Bool = false
}

private struct LoadedCityPlaces: View {
    let scale: CGFloat = 0.85

    @StateObject var page: Page = .first()
    @State var places: [PlaceTileState]
    @State private var isAwarding = false
    var city: String
    var submit: (_ places: [PlaceTileState]) -> Void

    var currentPlace: PlaceTileState { places[page.index] }

    var body: some View {
        VStack {
            Text("Here are some popular places in \(city)")
                .bold()
                .foregroundColor(.white)
                .padding(.top, 10)
            Spacer().frame(maxHeight: 50)
            mainBody
            Spacer()
        }.background(
            URLImage(url: currentPlace.tile.imageUrl)
                .scaledToFill()
                .frame(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height
                )
                .blur(radius: 20)
                .opacity(0.5)
                .background(Color.black)
        ).toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    submit(places)
                }
            }
        }
    }

    @ViewBuilder
    var mainBody: some View {
        VStack(spacing: 30) {
            Pager(page: page, data: places, id: \.tile.placeId) { item in
                VStack(alignment: .leading, spacing: 0) {
                    URLImage(url: item.tile.imageUrl)
                        .frame(
                            width: UIScreen.main.bounds.width * scale,
                            height: UIScreen.main.bounds.width * scale
                        )
                        .contentShape(Rectangle())
                        .clipped()
                    Text(item.tile.name)
                        .font(.system(size: 20, weight: .bold))
                        .bold()
                        .frame(height: 40)
                        .foregroundColor(.white)
                }
            }
            .preferredItemSize(
                CGSize(
                    width: UIScreen.main.bounds.width * scale,
                    height: UIScreen.main.bounds.width * scale + 40
                )
            )
            .itemSpacing(10)
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * scale + 40)

            VStack {
                if isAwarding {
                    HStack {
                        Button {
                            isAwarding = false
                        } label: {
                            Image(systemName: "chevron.left")
                                .resizable()
                                .foregroundColor(.white)
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .contentShape(Rectangle())
                        }

                        CreatePostStarPicker(
                            unselectedOutline: .white,
                            showZeroStars: false,
                            stars: $places[page.index].stars,
                            onTap: { isAwarding = false }
                        )
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                } else {
                    HStack(alignment: .top, spacing: 50) {
                        LikeButton(liked: currentPlace.post, stars: currentPlace.stars) {
                            if places[page.index].post {
                                places[page.index].post = false
                                places[page.index].stars = nil
                            } else {
                                places[page.index].post = true
                                isAwarding = true
                            }
                        } tapStars: {
                            isAwarding = true
                        }

                        SaveButton(saved: currentPlace.saved) {
                            places[page.index].saved = !places[page.index].saved
                        }
                    }
                }
            }.frame(height: 100)
        }
    }
}

private struct LikeButton: View {
    var liked: Bool
    var stars: Int?
    var tap: () -> Void
    var tapStars: () -> Void

    var body: some View {
        VStack {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                tap()
            } label: {
                Image(liked ? "icon" : "icon_white")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 65)
                    .grayscale(liked ? 0.0 : 1.0)
                    .contentShape(Rectangle())
            }
            .frame(height: 70)
            Text("Liked it").foregroundColor(.white)
            if let stars = stars {
                Button(action: tapStars) {
                    HStack(spacing: 2) {
                        ForEach(0..<stars, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
            }
            Spacer()
        }.frame(height: 120)
    }
}

private struct SaveButton: View {
    var saved: Bool
    var tap: () -> Void

    var body: some View {
        VStack {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                tap()
            } label: {
                Image(systemName: "bookmark")
                    .resizable()
                    .frame(width: 44, height: 60)
                    .foregroundColor(saved ? .orange : .white)
                    .contentShape(Rectangle())
            }
            .frame(height: 70)
            Text("Want to go").foregroundColor(.white)
            Spacer()
        }.frame(height: 120)
    }
}
