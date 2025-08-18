import Foundation

extension Date {
    var yakusokuDayKey: String {
        // 타임존 고정: Asia/Tokyo로 통일 (위젯과 앱 간 일관성 보장)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        let year = String(format: "%04d", components.year ?? 0)
        let month = String(format: "%02d", components.month ?? 0)
        let day = String(format: "%02d", components.day ?? 0)
        return "\(year)-\(month)-\(day)"
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
    
    static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}