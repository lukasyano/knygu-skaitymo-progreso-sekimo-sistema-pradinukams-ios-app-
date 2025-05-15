import SwiftUI

struct ProgressStatsView: View {
    @StateObject var viewModel = ProgressStatsViewModel()

    let user: UserEntity
    let onDailyProgressUpdated: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(user.name) savaitės skaitymo progresas")
                .font(.title2.bold())
                .padding(.bottom, 10)

            StatCard(title: "Savaitės skaitymo trukmė",
                     value: viewModel.stats.totalDuration.timeString,
                     systemImage: "clock.fill",
                     backgroundColor: .blue.opacity(0.1))

            StatCard(title: "Vidutiniškai per dieną",
                     value: viewModel.stats.averageDailyDuration.timeString,
                     systemImage: "chart.bar.fill",
                     backgroundColor: .green.opacity(0.1))

            StatCard(title: "Perskaityta puslapių",
                     value: "\(viewModel.stats.pagesRead)",
                     systemImage: "book.fill",
                     backgroundColor: .orange.opacity(0.1))

            StatCard(title: "Aktyvios dienos",
                     value: "\(viewModel.stats.daysActive)",
                     systemImage: "calendar",
                     backgroundColor: .purple.opacity(0.1))

            // ―–––––––––––––––––––––––––––––––––––––––––
            if let dailyReadingGoal = user.dailyReadingGoal {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dienos skaitymo tikslas")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Stepper(
                            value: .init(get: { user.dailyReadingGoal ?? 5 }, set: onDailyProgressUpdated),
                            in: 5 ... 300,
                            step: 5
                        ) {
                            Text("\(dailyReadingGoal) min")
                                .font(.title3.bold())
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .gray.opacity(0.3),
                                    radius: 4, x: 0, y: 2)
                    )
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .shadow(radius: 5)
        .onAppear {
            viewModel.loadStats(for: user.id)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    var backgroundColor: Color = .gray.opacity(0.1)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(backgroundColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3.bold())
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
