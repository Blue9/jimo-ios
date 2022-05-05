//
//  ShareButtonView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/5/22.
//

import SwiftUI

struct ShareButtonView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @State private var showShareSheet = false
    var url: URL
    
    var body: some View {
        Button {
            showShareSheet = true
        } label: {
            Group {
                if showShareSheet {
                    ProgressView()
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .offset(y: -2)
                }
            }
            .scaledToFit()
            .frame(width: 25, height: 25)
            .padding()
        }
        .background(ActivityView(activityItems: [url], applicationActivities: nil, isPresented: $showShareSheet))
    }
}
