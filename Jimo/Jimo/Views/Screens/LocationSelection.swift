//
//  LocationSelection.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/10/20.
//

import SwiftUI
import MapKit

struct ActionButton: View {
    var text: String
    var color = Color.blue
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .frame(width: 100)
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(color)
                .cornerRadius(10)
        }
    }
}

private struct LocationSelectionPin: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .resizable()
                .foregroundColor(.blue)
                .background(Color.white.cornerRadius(20))
                .frame(width: 40, height: 40, alignment: .center)
            Image(systemName: "circle.fill")
                .resizable()
                .foregroundColor(.blue)
                .frame(width: 6, height: 6, alignment: .center)
        }
        .offset(y: -22)
    }
}

struct LocationSelection: View {
    @State var mapRegion: MKCoordinateRegion
    @Binding var active: Bool
    
    var afterConfirm: (MKCoordinateRegion) -> Void

    var body: some View {
        ZStack {
            Map(coordinateRegion: $mapRegion)
            LocationSelectionPin()
            VStack {
                Spacer()
                HStack {
                    ActionButton(text: "Cancel", color: .gray, action: {
                        self.active = false
                    })
                    Spacer(minLength: 20)
                    ActionButton(text: "Update", action: {
                        self.active = false
                        self.afterConfirm(mapRegion)
                    })
                }
                .padding(.horizontal, 70)
            }
            .padding(.bottom, 60)
        }
    }
}

struct LocationSelection_Previews: PreviewProvider {
    static var mapRegion = defaultRegion
    @State static var active = true
    @State static var selectedRegion: MKCoordinateRegion? = nil
    
    static var previews: some View {
        LocationSelection(mapRegion: mapRegion, active: $active, afterConfirm: {_ in })
    }
}
