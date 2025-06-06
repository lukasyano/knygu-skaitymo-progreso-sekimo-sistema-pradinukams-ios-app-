//
//  LoadingThreeBallsRotation.swift
//  SwiftfulLoadingIndicators
//
//  Created by Nick Sarno on 1/12/21.
//

import Combine
import SwiftUI

struct LoadingThreeBallsRotation: View {
    @State var isAnimating: Bool = false
    let timing: Double

    let maxCounter = 3

    let frame: CGSize
    let primaryColor: Color

    init(color: Color = .black, size: CGFloat = 50, speed: Double = 0.5) {
        self.timing = speed * 1.5
        self.frame = CGSize(width: size, height: size)
        self.primaryColor = color
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0 ..< maxCounter) { _ in
                Circle()
                    .fill(primaryColor)
            }
        }
        .frame(width: frame.width, height: frame.height, alignment: .center)
        .rotationEffect(Angle(degrees: isAnimating ? 180 : 0))
        .onAppear {
            withAnimation(Animation.easeInOut(duration: timing).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct LoadingThreeBallsRotation_Previews: PreviewProvider {
    static var previews: some View {
        LoadingPreviewView(animation: .threeBallsRotation)
    }
}
