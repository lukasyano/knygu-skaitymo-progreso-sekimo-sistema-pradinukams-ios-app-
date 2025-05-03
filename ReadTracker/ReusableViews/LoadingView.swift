import Lottie
import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()

            LottieView(animation: .named("loading.json")).playing().playing(loopMode: .autoReverse)
        }
    }
}
