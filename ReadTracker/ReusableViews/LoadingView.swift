import Lottie
import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()
            VStack {
                LottieView(animation: .named("loading.json"))
                    .playing(loopMode: .autoReverse)

                LoadingIndicator(animation: .text, size: .large)
            }
        }
    }
}
