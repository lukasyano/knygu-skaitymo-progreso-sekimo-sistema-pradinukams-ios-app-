//
//  LoadingPulse.swift
//  SwiftfulLoadingIndicators
//
//  Created by Nick Sarno on 1/12/21.
//

import SwiftUI

struct LoadingPulse: View {
    @State var isAnimating: Bool = false
    let timing: Double

    let maxCounter: Int = 3

    let frame: CGSize
    let primaryColor: Color

    init(color: Color = .black, size: CGFloat = 50, speed: Double = 0.5) {
        self.timing = speed * 4
        self.frame = CGSize(width: size, height: size)
        self.primaryColor = color
    }

    var body: some View {
        ZStack {
            ForEach(0 ..< maxCounter) { index in
                Circle()
                    .scale(isAnimating ? 1.0 : 0.0)
                    .fill(primaryColor)
                    .opacity(isAnimating ? 0.0 : 1.0)
                    .animation(
                        Animation.easeOut(duration: timing)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * timing / 3)
                    )
            }
        }
        .frame(width: frame.width, height: frame.height, alignment: .center)
        .onAppear {
            isAnimating.toggle()
        }
    }
}

struct LoadingPulse_Previews: PreviewProvider {
    static var previews: some View {
        LoadingPreviewView(animation: .pulse)
    }
}
