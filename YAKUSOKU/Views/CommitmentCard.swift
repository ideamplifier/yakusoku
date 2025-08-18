import SwiftUI
import SwiftData

struct CommitmentCard: View {
    let commitment: Commitment
    @Environment(\.modelContext) private var modelContext
    @Query private var checkins: [Checkin]
    
    @State private var todayCheckin: Checkin?
    @State private var showingIfThen = false
    @State private var todayScore: Score = .meh
    
    private var todayKey: String {
        Date().yakusokuDayKey
    }
    
    private var todayRating: Rating? {
        checkins.first { 
            $0.commitmentID == commitment.id && 
            $0.dayKey == todayKey 
        }?.rating
    }
    
    private var recentCheckins: [Checkin] {
        let sevenDaysAgo = Date.daysAgo(7)
        return checkins
            .filter { $0.commitmentID == commitment.id && $0.date >= sevenDaysAgo }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 약속 제목
            VStack(alignment: .leading, spacing: 8) {
                Text(commitment.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(YKColor.ink)
                    .lineLimit(2)
                
                if let ifThen = commitment.ifThen, !ifThen.isEmpty {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            showingIfThen.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showingIfThen ? "chevron.up.circle" : "chevron.down.circle")
                                .font(.caption)
                            Text("If-Then 전략")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(YKColor.secondaryText)
                    }
                    
                    if showingIfThen {
                        Text(ifThen)
                            .font(.caption)
                            .foregroundStyle(YKColor.secondaryText)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(YKColor.mint.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(YKColor.ink.opacity(0.1), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            
            // 7일 인디케이터와 체크인 버튼
            HStack(spacing: 12) {
                SevenDayIndicator(checkins: recentCheckins)
                
                Spacer()
                
                // TrafficScorePicker로 교체
                if let rating = todayRating {
                    TrafficScorePicker(selection: .init(
                        get: { Score(from: rating) },
                        set: { newScore in
                            performCheckin(rating: newScore.toRating)
                        }
                    ))
                    .frame(width: 180)
                } else {
                    TrafficScorePicker(selection: .init(
                        get: { .meh },
                        set: { newScore in
                            performCheckin(rating: newScore.toRating)
                        }
                    ))
                    .frame(width: 180)
                }
            }
        }
        .stickerCard()
    }
    
    private func performCheckin(rating: Rating) {
        let dayKey = Date().yakusokuDayKey
        
        let commitmentID = commitment.id
        let descriptor = FetchDescriptor<Checkin>(
            predicate: #Predicate { checkin in
                checkin.commitmentID == commitmentID && checkin.dayKey == dayKey
            }
        )
        
        if let existingCheckin = try? modelContext.fetch(descriptor).first {
            existingCheckin.rating = rating
            existingCheckin.date = Date()
        } else {
            let newCheckin = Checkin(
                commitmentID: commitment.id,
                dayKey: dayKey,
                rating: rating
            )
            modelContext.insert(newCheckin)
        }
        
        try? modelContext.save()
        HapticFeedback.success()
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
        HStack(spacing: 6) {
            ForEach(0..<7) { day in
                VStack(spacing: 4) {
                    Circle()
                        .fill(colorForRating(ratingForDay(day)))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(YKColor.ink.opacity(0.4), lineWidth: 1)
                        )
                    
                    Text(dayLabel(day))
                        .font(.system(size: 8))
                        .foregroundStyle(YKColor.ink.opacity(0.6))
                }
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
        case .good: return YKColor.green
        case .meh: return YKColor.yellow
        case .poor: return YKColor.red
        case nil: return YKColor.card
        }
    }
}