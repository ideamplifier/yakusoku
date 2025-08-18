import SwiftUI
import SwiftData

struct CommitmentCard: View {
    let commitment: Commitment
    @Environment(\.modelContext) private var modelContext
    
    // 최적화: 이 commitment의 최근 7일 체크인만 쿼리
    @Query private var recentCheckins: [Checkin]
    
    @State private var showingIfThen = false
    
    init(commitment: Commitment) {
        self.commitment = commitment
        
        // 최근 7일간의 체크인만 필터링해서 가져오기
        let commitmentID = commitment.id
        let sevenDaysAgo = Date.daysAgo(7)
        
        _recentCheckins = Query(
            filter: #Predicate<Checkin> { checkin in
                checkin.commitmentID == commitmentID && 
                checkin.date >= sevenDaysAgo
            },
            sort: [SortDescriptor(\.date, order: .reverse)]
        )
    }
    
    private var todayKey: String {
        Date().yakusokuDayKey
    }
    
    private var todayRating: Rating? {
        recentCheckins.first { $0.dayKey == todayKey }?.rating
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(commitment.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let ifThen = commitment.ifThen, !ifThen.isEmpty {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            showingIfThen.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: showingIfThen ? "chevron.up.circle" : "chevron.down.circle")
                                .font(.caption)
                                .foregroundStyle(.black.opacity(0.35))
                            Text("If-Then 전략")
                                .font(.caption)
                                .foregroundStyle(.black.opacity(0.55))
                        }
                    }
                    
                    if showingIfThen {
                        Text(ifThen)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(YKColor.mint.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            
            VStack(spacing: 14) {
                SevenDayIndicator(checkins: recentCheckins)
                
                TrafficScorePicker(selection: .init(
                    get: { Score(from: todayRating ?? .meh) },
                    set: { newScore in
                        performCheckin(rating: newScore.toRating)
                    }
                ))
                .frame(maxWidth: .infinity, minHeight: 52)
            }
        }
        .stickerCard()
    }
    
    private func performCheckin(rating: Rating) {
        let dayKey = Date().yakusokuDayKey
        let commitmentID = commitment.id
        
        // 중복 방지: 오늘 이미 체크인이 있는지 확인
        var descriptor = FetchDescriptor<Checkin>(
            predicate: #Predicate { checkin in
                checkin.commitmentID == commitmentID && checkin.dayKey == dayKey
            }
        )
        descriptor.fetchLimit = 1
        
        if let existingCheckin = try? modelContext.fetch(descriptor).first {
            // 업데이트
            existingCheckin.rating = rating
            existingCheckin.date = Date()
        } else {
            // 새로 생성
            let newCheckin = Checkin(
                commitmentID: commitment.id,
                dayKey: dayKey,
                rating: rating
            )
            modelContext.insert(newCheckin)
        }
        
        try? modelContext.save()
        HapticFeedback.light()
    }
}


struct SevenDayIndicator: View {
    let checkins: [Checkin]
    
    private func ratingForDay(_ day: Int) -> Rating? {
        let date = Date.daysAgo(6 - day)
        let dayKey = date.yakusokuDayKey
        return checkins.first { $0.dayKey == dayKey }?.rating
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<7) { day in
                VStack(spacing: 8) {
                    Circle()
                        .fill(colorForRating(ratingForDay(day)))
                        .frame(width: 8, height: 8)
                    
                    Text(dayLabel(day))
                        .font(.system(size: 8))
                        .foregroundStyle(.black.opacity(0.55))
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func dayLabel(_ day: Int) -> String {
        let date = Date.daysAgo(6 - day)
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ko_KR")
        return String(formatter.string(from: date).prefix(1))
    }
    
    private func colorForRating(_ rating: Rating?) -> Color {
        switch rating {
        case .good:
            return YKColor.green
        case .meh:
            return YKColor.yellow
        case .poor:
            return YKColor.red
        case nil:
            return .black.opacity(0.4)
        }
    }
}