//
//  RequestPermission.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/27/22.
//

import SwiftUI

struct RequestPermission: View {
    @State private var requesting = false
    
    var onCompleteRequest: () -> ()
    
    var action: () -> ()
    var title: String
    var imageName: String
    var caption: String
    
    func request() {
        action()
        withAnimation {
            self.requesting = true
        }
    }
    
    func next() {
        withAnimation {
            self.onCompleteRequest()
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.system(size: 24))
                .multilineTextAlignment(.center)
                .padding(40)
            
            Group {
                Image(imageName)
                
                Text(caption)
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                if !requesting {
                    Button(action: {
                        request()
                    }) {
                        LargeButton("Enable", fontSize: 20)
                    }
                    
                    Button(action: {
                        next()
                    }) {
                        Text("Not now")
                            .font(.system(size: 20))
                    }
                } else {
                    Button(action: {
                        next()
                    }) {
                        Text("Next")
                            .font(.system(size: 20))
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 60)
                            .foregroundColor(Color("foreground"))
                            .background(Color("next-button"))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            .foregroundColor(Color("foreground"))
            .padding(.horizontal, 80)
            .padding(.bottom, 100)
        }
    }
}
