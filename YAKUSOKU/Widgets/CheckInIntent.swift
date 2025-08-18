import AppIntents
import SwiftData
import WidgetKit

struct CheckInIntent: AppIntent {
    static var title: LocalizedStringResource = "체크인"
    static var description = IntentDescription("약속에 대한 체크인을 기록합니다")
    
    @Parameter(title: "Commitment ID")
    var commitmentID: String
    
    @Parameter(title: "Rating")
    var ratingRaw: Int
    
    @Parameter(title: "Day Key")
    var dayKey: String
    
    init() {
        self.commitmentID = ""
        self.ratingRaw = 0
        self.dayKey = ""
    }
    
    init(commitmentID: String, ratingRaw: Int, dayKey: String) {
        self.commitmentID = commitmentID
        self.ratingRaw = ratingRaw
        self.dayKey = dayKey
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        do {
            let container = try SharedContainer.container()
            let context = container.mainContext
            
            let rating = Rating(rawValue: ratingRaw) ?? .meh
            
            let existingCheckinDescriptor = FetchDescriptor<Checkin>(
                predicate: #Predicate { checkin in
                    checkin.commitmentID == commitmentID && checkin.dayKey == dayKey
                }
            )
            
            if let existingCheckin = try context.fetch(existingCheckinDescriptor).first {
                existingCheckin.rating = rating
                existingCheckin.date = Date()
            } else {
                let newCheckin = Checkin(
                    commitmentID: commitmentID,
                    dayKey: dayKey,
                    rating: rating
                )
                context.insert(newCheckin)
            }
            
            try context.save()
            
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
            print("Failed to perform check-in: \(error)")
        }
        
        return .result()
    }
}