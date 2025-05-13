import SwiftData
import Foundation

@Model
class ReadingSession {
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval 

    init(startTime: Date, endTime: Date, duration: TimeInterval) {
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
    }
}
