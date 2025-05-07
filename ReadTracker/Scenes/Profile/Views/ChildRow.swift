import SwiftUI

struct ChildRow: View {
    let child: UserEntity

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(child.name)
                    .fontWeight(.medium)
                Text(child.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(child.totalPoints) taškų")
                .font(.subheadline)
                .foregroundColor(.orange)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground)))
    }
}
