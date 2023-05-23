//
//  CityOnboarding.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/11/23.
//

import SwiftUI

struct CityOnboarding: View {
    @State private var selectedCity: SelectedCity?

    var selectCity: (SelectedCity) -> Void

    var body: some View {
        VStack {
            Text("Get started by selecting a city")
                .font(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(
                "On the next page, we'll show you popular places from your city " +
                "to help you get started with your profile."
            )
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundColor(.gray)
            .padding(.top)
            .padding(.horizontal)

            Spacer()

            VStack {
                cityButton(.nyc, color: .green)
                cityButton(.la, color: .orange)
                cityButton(.chicago, color: .blue)
                cityButton(.london, color: .purple)
                cityButton(.other, color: .gray)
            }

            Spacer()

            VStack {
                if let city = selectedCity {
                    Button {
                        selectCity(city)
                    } label: {
                        Text("Next")
                            .foregroundColor(Color("foreground"))
                            .bold()
                            .frame(width: 240, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        Color("foreground"),
                                        style: StrokeStyle(lineWidth: 2)
                                    )
                            )
                    }
                }
            }
            .frame(height: 100)
        }
        .frame(maxWidth: 300)
        .padding(.top, 40)
    }

    @ViewBuilder
    private func cityButton(_ city: SelectedCity, color: Color) -> some View {
        Button {
            if selectedCity == city {
                selectedCity = nil
            } else {
                selectedCity = city
            }
        } label: {
            Text(city.name)
                .bold()
                .frame(width: 240, height: 50)
                .foregroundColor(
                    selectedCity == city ? .white : Color("foreground")
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            color,
                            style: StrokeStyle(lineWidth: 2)
                        )
                )
                .background(selectedCity == city ? color.cornerRadius(10) : nil)
        }
    }
}
