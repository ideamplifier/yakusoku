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
            
            // 중복 방지: fetchLimit 추가로 성능 향상
            var existingCheckinDescriptor = FetchDescriptor<Checkin>(
                predicate: #Predicate { checkin in
                    checkin.commitmentID == commitmentID && checkin.dayKey == dayKey
                }
            )
            existingCheckinDescriptor.fetchLimit = 1  // 성능 최적화: 첫 번째 결과만 가져오기
            
            if let existingCheckin = try context.fetch(existingCheckinDescriptor).first {
                // 기존 체크인 업데이트
                existingCheckin.rating = rating
                existingCheckin.date = Date()
                print("Updated existing checkin for \(commitmentID) on \(dayKey)")
            } else {
                // 새로운 체크인 생성
                let newCheckin = Checkin(
                    commitmentID: commitmentID,
                    dayKey: dayKey,
                    rating: rating
                )
                context.insert(newCheckin)
                print("Created new checkin for \(commitmentID) on \(dayKey)")
            }
            
            try context.save()
            
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
            print("Failed to perform check-in: \(error)")
        }
        
        return .result()
    }
}