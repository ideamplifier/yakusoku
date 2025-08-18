import SwiftUI
import SwiftData

struct WeeklyReportMinimalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var commitments: [Commitment]
    @Query private var checkins: [Checkin]
    
    @State private var selectedWeek = 0
    
    private var weekDates: [Date] {
        (0..<7).map { Date.daysAgo(6 - $0 - (selectedWeek * 7)) }
    }
    
    private var weeklyStats: WeeklyStatistics {
        calculateWeeklyStats()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 주간 선택기
                    WidgetBlock {
                        WeekSelectorWidget(selectedWeek: $selectedWeek)
                    }
                    
                    // 전체 통계 (2열)
                    HStack(spacing: 12) {
                        WidgetBlock {
                            StatWidget(
                                title: "달성률",
                                value: "\(Int(weeklyStats.successRate * 100))%",
                                color: weeklyStats.successRate > 0.7 ? MColor.green : 
                                       weeklyStats.successRate > 0.3 ? MColor.yellow : MColor.red
                            )
                        }
                        
                        WidgetBlock {
                            StatWidget(
                                title: "완료",
                                value: "\(weeklyStats.goodCount)/\(weeklyStats.totalCheckins)",
                                color: MColor.ink
                            )
                        }
                    }
                    
                    // 약속별 카드
                    ForEach(commitments) { commitment in
                        WidgetBlock {
                            CommitmentStatCard(
                                commitment: commitment,
                                weekDates: weekDates,
                                checkins: checkinsForCommitment(commitment)
                            )
                        }
                    }
                    
                    Spacer(minLength: 80)
                }
                .padding(16)
            }
            .background(MColor.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("주간 리포트")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MColor.ink)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(MColor.ink)
                }
            }
        }
    }
    
    private func checkinsForCommitment(_ commitment: Commitment) -> [Checkin] {
        checkins.filter { checkin in
            checkin.commitmentID == commitment.id &&
            weekDates.contains { $0.yakusokuDayKey == checkin.dayKey }
        }
    }
    
    private func calculateWeeklyStats() -> WeeklyStatistics {
        var totalCheckins = 0
        var goodCount = 0
        var mehCount = 0
        var poorCount = 0
        
        for commitment in commitments {
            let weekCheckins = checkinsForCommitment(commitment)
            totalCheckins += weekCheckins.count
            
            for checkin in weekCheckins {
                switch checkin.rating {
                case .good: goodCount += 1
                case .meh: mehCount += 1
                case .poor: poorCount += 1
                }
            }
        }
        
        let possibleCheckins = commitments.count * 7
        let completionRate = possibleCheckins > 0 ? 
            Double(totalCheckins) / Double(possibleCheckins) : 0
        
        let successRate = totalCheckins > 0 ?
            Double(goodCount) / Double(totalCheckins) : 0
        
        return WeeklyStatistics(
            totalCheckins: totalCheckins,
            goodCount: goodCount,
            mehCount: mehCount,
            poorCount: poorCount,
            completionRate: completionRate,
            successRate: successRate
        )
    }
}

// MARK: - Week Selector Widget
struct WeekSelectorWidget: View {
    @Binding var selectedWeek: Int
    
    private var weekRangeText: String {
        let startDate = Date.daysAgo(6 + (selectedWeek * 7))
        let endDate = Date.daysAgo(selectedWeek * 7)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var body: some View {
        HStack {
            Button {
                selectedWeek += 1
                HapticFeedback.light()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(selectedWeek >= 4 ? MColor.tertiaryText : MColor.ink)
            }
            .disabled(selectedWeek >= 4)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(selectedWeek == 0 ? "이번 주" : "\(selectedWeek)주 전")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MColor.ink)
                Text(weekRangeText)
                    .font(.caption)
                    .foregroundStyle(MColor.secondaryText)
            }
            
            Spacer()
            
            Button {
                selectedWeek -= 1
                HapticFeedback.light()
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(selectedWeek <= 0 ? MColor.tertiaryText : MColor.ink)
            }
            .disabled(selectedWeek <= 0)
        }
    }
}

// MARK: - Stat Widget
struct StatWidget: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(MColor.secondaryText)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Commitment Stat Card
struct CommitmentStatCard: View {
    let commitment: Commitment
    let weekDates: [Date]
    let checkins: [Checkin]
    
    private func ratingForDate(_ date: Date) -> Rating? {
        checkins.first { $0.dayKey == date.yakusokuDayKey }?.rating
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(commitment.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(MColor.ink)
            
            HStack(spacing: 8) {
                ForEach(weekDates, id: \.self) { date in
                    VStack(spacing: 6) {
                        Text(dayLabel(date))
                            .font(.system(size: 10))
                            .foregroundStyle(MColor.secondaryText)
                        
                        Circle()
                            .fill(colorForRating(ratingForDate(date)))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Group {
                                    if let rating = ratingForDate(date) {
                                        Image(systemName: iconForRating(rating))
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white)
                                    }
                                }
                            )
                    }
                }
            }
        }
    }
    
    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ko_KR")
        return String(formatter.string(from: date).prefix(1))
    }
    
    private func colorForRating(_ rating: Rating?) -> Color {
        switch rating {
        case .good: return MColor.green
        case .meh: return MColor.yellow
        case .poor: return MColor.red
        case nil: return MColor.border
        }
    }
    
    private func iconForRating(_ rating: Rating) -> String {
        switch rating {
        case .good: return "checkmark"
        case .meh: return "minus"
        case .poor: return "xmark"
        }
    }
}

#Preview {
    WeeklyReportMinimalView()
        .modelContainer(for: [Commitment.self, Checkin.self])
}