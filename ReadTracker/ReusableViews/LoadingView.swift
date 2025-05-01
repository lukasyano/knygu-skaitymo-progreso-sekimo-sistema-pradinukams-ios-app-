import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
                .blur(radius: 50)
            
            ProgressView(label: { Text("Kraunama") })
        }
    }
}
