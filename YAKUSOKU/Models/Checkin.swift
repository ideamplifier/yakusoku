import SwiftData
import Foundation

enum Rating: Int, Codable, CaseIterable {
    case poor = 0
    case meh = 1
    case good = 2
    
    var emoji: String {
        switch self {
        case .poor: return "😣"
        case .meh: return "😐"
        case .good: return "🙂"
        }
    }
    
    var label: String {
        switch self {
        case .poor: return "못함"
        case .meh: return "보통"
        case .good: return "잘함"
        }
    }
}

@Model
final class Checkin {
    @Attribute(.unique) var id: String
    var commitmentID: String
    var dayKey: String
    var date: Date
    var ratingRaw: Int
    var note: String?
    var triggerTag: String?
    
    var rating: Rating {
        get { Rating(rawValue: ratingRaw) ?? .meh }
        set { ratingRaw = newValue.rawValue }
    }
    
    init(
        id: String = UUID().uuidString,
        commitmentID: String,
        dayKey: String,
        date: Date = .now,
        rating: Rating,
        note: String? = nil,
        triggerTag: String? = nil
    ) {
        self.id = id
        self.commitmentID = commitmentID
        self.dayKey = dayKey
        self.date = date
        self.ratingRaw = rating.rawValue
        self.note = note
        self.triggerTag = triggerTag
    }
}