
import Combine
import Foundation
import Resolver

struct WeeklyReadingStats {
    let totalDuration: TimeInterval
    let averageDailyDuration: TimeInterval
    let pagesRead: Int
    let daysActive: Int
}

@MainActor
final class ProgressStatsViewModel: ObservableObject {
    @Published var stats = WeeklyReadingStats(
        totalDuration: 0,
        averageDailyDuration: 0,
        pagesRead: 0,
        daysActive: 0
    )
    
    @Injected private var firestoreService: UsersFirestoreService
    private var cancellables = Set<AnyCancellable>()
    
    func loadStats(for userId: String) {
        firestoreService.getWeeklyStats(userID: userId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] stats in
                self?.stats = stats
            })
            .store(in: &cancellables)
    }
}

// Add this extension for time formatting
extension TimeInterval {
    var timeString: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        return String(format: "%02d h %02d min", hours, minutes)
    }
    var asMinutes: Int {
        return Int(self / 60)
    }
}
