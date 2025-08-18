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
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("주간 리포트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
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
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(selectedWeek >= 4)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(selectedWeek == 0 ? "이번 주" : "\(selectedWeek)주 전")
                    .font(.headline)
                Text(weekRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                selectedWeek -= 1
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(selectedWeek <= 0)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct OverallScoreCard: View {
    let stats: WeeklyStatistics
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("전체 달성률")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(stats.successRate * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    StatBadge(emoji: "🙂", count: stats.goodCount, color: .green)
                    StatBadge(emoji: "😐", count: stats.mehCount, color: .orange)
                    StatBadge(emoji: "😣", count: stats.poorCount, color: .red)
                }
            }
            
            ProgressView(value: stats.successRate)
                .tint(.green)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatBadge: View {
    let emoji: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.title2)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(width: 50, height: 50)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        VStack(alignment: .leading, spacing: 12) {
            Text(commitment.title)
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(weekDates, id: \.self) { date in
                    VStack(spacing: 4) {
                        Text(date.weekdayString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Circle()
                            .fill(colorForRating(ratingForDate(date)))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(ratingForDate(date)?.emoji ?? "")
                                    .font(.caption)
                            )
                    }
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func colorForRating(_ rating: Rating?) -> Color {
        switch rating {
        case .good: return .green.opacity(0.2)
        case .meh: return .orange.opacity(0.2)
        case .poor: return .red.opacity(0.2)
        case nil: return .secondary.opacity(0.1)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("이번 주 인사이트", systemImage: "lightbulb.fill")
                .font(.headline)
            
            Text(insightText)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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