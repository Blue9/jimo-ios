//
//  Wave.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/9/21.
//

import SwiftUI

struct Wave: View {
    
    var bounds = UIScreen.main.bounds
    
    var body: some View {
        ZStack {
            sineWave(interval: bounds.width * 2, amplitude: 200, baseline: 100 + bounds.height / 2)
                .foregroundColor(Color("attraction"))
                .opacity(0.33)
            sineWave(interval: bounds.width * 3.5, amplitude: 300, baseline: 125 + bounds.height / 2)
                .foregroundColor(Color("attraction"))
                .opacity(0.33)
        }
        .ignoresSafeArea(.all, edges: .all)
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
    
    func sineWave(interval: CGFloat, amplitude: CGFloat = 100, baseline: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: baseline))
            path.addCurve(
                to: .init(x: interval, y: baseline),
                control1: .init(x: interval * 0.4, y: amplitude + baseline),
                control2: .init(x: interval * 0.6, y: -amplitude + baseline))
            path.addCurve(
                to: .init(x: interval * 2, y: baseline),
                control1: .init(x: interval * 1.4, y: amplitude + baseline),
                control2: .init(x: interval * 1.6, y: -amplitude + baseline))
            path.addLine(to: CGPoint(x: interval * 2, y: bounds.height))
            path.addLine(to: CGPoint(x: 0, y: bounds.height))
        }
    }
}

struct Wave_Previews: PreviewProvider {
    static var previews: some View {
        Wave()
    }
}
