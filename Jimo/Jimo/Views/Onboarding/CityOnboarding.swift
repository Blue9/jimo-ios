//
//  CityOnboarding.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/11/23.
//

import SwiftUI

struct CityOnboarding: View {
    @State private var selectedCity: String?

    var selectCity: (String) -> Void

    var body: some View {
        VStack {
            Text("Get started by selecting a city")
                .font(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer()

            VStack {
                cityButton("New York", color: .green)
                cityButton("Los Angeles", color: .orange)
                cityButton("Chicago", color: .blue)
                cityButton("London", color: .purple)
            }

            Spacer()

            Text(
                "Not from any of these cities?\nAll good—you can Jimo anywhere in the world!"
            )
            .frame(width: 240)
            .multilineTextAlignment(.center)
            .foregroundColor(.gray)

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
    func cityButton(_ city: String, color: Color) -> some View {
        Button {
            if selectedCity == city {
                selectedCity = nil
            } else {
                selectedCity = city
            }
        } label: {
            Text(city)
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

struct CityOnboarding_Previews: PreviewProvider {
    static var previews: some View {
        Navigator {
            CityOnboarding(selectCity: {_ in})
                .navigationBarHidden(true)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
    }
}
