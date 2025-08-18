import SwiftUI
import SwiftData
import Charts

struct WeeklyReportView: View {
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
                VStack(spacing: 20) {
                    WeekSelector(selectedWeek: $selectedWeek)
                    
                    OverallScoreCard(stats: weeklyStats)
                    
                    if !commitments.isEmpty {
                        ForEach(commitments) { commitment in
                            CommitmentWeeklyCard(
                                commitment: commitment,
                                weekDates: weekDates,
                                checkins: checkinsForCommitment(commitment)
                            )
                        }
                    }
                    
                    InsightCard(stats: weeklyStats)
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(ZenColors.background)
            .navigationTitle("주간 리포트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(ZenColors.primaryGreen)
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

struct WeekSelector: View {
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
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(selectedWeek >= 4 ? ZenColors.tertiaryText : ZenColors.primaryGreen)
            }
            .disabled(selectedWeek >= 4)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(selectedWeek == 0 ? "이번 주" : "\(selectedWeek)주 전")
                    .font(.headline)
                    .foregroundStyle(ZenColors.primaryText)
                Text(weekRangeText)
                    .font(.caption)
                    .foregroundStyle(ZenColors.secondaryText)
            }
            
            Spacer()
            
            Button {
                selectedWeek -= 1
                HapticFeedback.light()
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(selectedWeek <= 0 ? ZenColors.tertiaryText : ZenColors.primaryGreen)
            }
            .disabled(selectedWeek <= 0)
        }
        .padding(20)
        .background(
            ZStack {
                Color.white
                LinearGradient(
                    colors: [
                        Color.white,
                        ZenColors.tertiaryGreen.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            ZenColors.primaryGreen.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: ZenColors.primaryGreen.opacity(0.08),
            radius: 20,
            x: 0,
            y: 10
        )
    }
}

struct OverallScoreCard: View {
    let stats: WeeklyStatistics
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("전체 달성률")
                        .font(.caption)
                        .foregroundStyle(ZenColors.secondaryText)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(stats.successRate * 100))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ZenColors.primaryGreen, ZenColors.secondaryGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("%")
                            .font(.title2)
                            .foregroundStyle(ZenColors.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    StatBadge(rating: .good, count: stats.goodCount)
                    StatBadge(rating: .meh, count: stats.mehCount)
                    StatBadge(rating: .poor, count: stats.poorCount)
                }
            }
            
            ProgressView(value: stats.successRate)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(ZenColors.primaryGreen)
                .scaleEffect(y: 2)
        }
        .padding(20)
        .background(
            ZStack {
                Color.white
                LinearGradient(
                    colors: [
                        Color.white,
                        ZenColors.tertiaryGreen.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            ZenColors.primaryGreen.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: ZenColors.primaryGreen.opacity(0.08),
            radius: 20,
            x: 0,
            y: 10
        )
    }
}

struct StatBadge: View {
    let rating: Rating
    let count: Int
    
    private var color: Color {
        switch rating {
        case .good: return ZenColors.goodColor
        case .meh: return ZenColors.mehColor
        case .poor: return ZenColors.poorColor
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            FluentEmoji(rating: rating, size: 24, isSelected: true)
                .foregroundStyle(color)
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(ZenColors.primaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct CommitmentWeeklyCard: View {
    let commitment: Commitment
    let weekDates: [Date]
    let checkins: [Checkin]
    
    private func ratingForDate(_ date: Date) -> Rating? {
        checkins.first { $0.dayKey == date.yakusokuDayKey }?.rating
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(commitment.title)
                .font(.headline)
                .foregroundStyle(ZenColors.primaryText)
            
            HStack(spacing: 6) {
                ForEach(weekDates, id: \.self) { date in
                    VStack(spacing: 8) {
                        Text(date.weekdayString)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(ZenColors.secondaryText)
                        
                        if let rating = ratingForDate(date) {
                            FluentEmoji(rating: rating, size: 28, isSelected: true)
                                .foregroundStyle(colorForRating(rating))
                                .frame(width: 36, height: 36)
                                .background(colorForRating(rating).opacity(0.15))
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .stroke(ZenColors.tertiaryText.opacity(0.2), lineWidth: 2)
                                .frame(width: 36, height: 36)
                        }
                    }
                }
            }
        }
        .zenCard()
    }
    
    private func colorForRating(_ rating: Rating) -> Color {
        switch rating {
        case .good: return ZenColors.goodColor
        case .meh: return ZenColors.mehColor
        case .poor: return ZenColors.poorColor
        }
    }
}

struct InsightCard: View {
    let stats: WeeklyStatistics
    
    private var insightText: String {
        if stats.totalCheckins == 0 {
            return "이번 주는 기록이 없어요. 작은 시작이 큰 변화를 만들어요!"
        } else if stats.successRate >= 0.8 {
            return "훌륭해요! 이번 주 목표를 잘 달성했어요. 다음 주도 이 기세를 유지해봐요!"
        } else if stats.successRate >= 0.5 {
            return "좋은 진전이 있었어요! 조금 더 노력하면 더 나은 결과를 얻을 수 있어요."
        } else {
            return "실패는 성공의 어머니예요. If-Then 전략을 다시 점검해보는 건 어떨까요?"
        }
    }
    
    private var insightIcon: String {
        if stats.totalCheckins == 0 {
            return "sparkles"
        } else if stats.successRate >= 0.8 {
            return "star.fill"
        } else if stats.successRate >= 0.5 {
            return "arrow.up.circle.fill"
        } else {
            return "lightbulb.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("이번 주 인사이트", systemImage: insightIcon)
                .font(.headline)
                .foregroundStyle(ZenColors.primaryGreen)
            
            Text(insightText)
                .font(.body)
                .foregroundStyle(ZenColors.secondaryText)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [ZenColors.primaryGreen.opacity(0.1), ZenColors.secondaryGreen.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(ZenColors.primaryGreen.opacity(0.2), lineWidth: 1)
        )
    }
}

struct WeeklyStatistics {
    let totalCheckins: Int
    let goodCount: Int
    let mehCount: Int
    let poorCount: Int
    let completionRate: Double
    let successRate: Double
}

#Preview {
    WeeklyReportView()
        .modelContainer(for: [Commitment.self, Checkin.self])
}