//
//  FirstOpenPopup.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/12/23.
//

import SwiftUI

struct FirstOpenPopup: View {
    @Binding var isPresented: Bool
    let goToProfile: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Welcome to Jimo!")
                .foregroundColor(.black)
                .font(.system(size: 20))

            welcomeText
                .font(.system(size: 12))
                .foregroundColor(.black)
                .opacity(0.6)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            buttons
        }
        .padding(EdgeInsets(top: 37, leading: 24, bottom: 40, trailing: 24))
        .background(Color.white.cornerRadius(10))
        .padding(.horizontal, 16)
    }

    var welcomeText: Text {
        Text("We're so glad you're here. " +
             "Track your favorite places, save ones you want to visit, " +
             "and discover new spots through other people's recommendations." +
             ""
        )
    }

    @ViewBuilder
    var buttons: some View {
        Button {
            isPresented = false
        } label: {
            Text("Start exploring").bold()
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.white)
                .background(Color("lodging"))
                .cornerRadius(10)
        }

        Button {
            DispatchQueue.main.async {
                isPresented = false
                goToProfile()
            }
        } label: {
            Text("Go to my profile").bold()
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(Color("lodging"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10).stroke(Color("lodging"), lineWidth: 2)
                    )
        }
    }
}
