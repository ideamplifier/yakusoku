import SwiftUI
import SwiftData
import Charts

struct WeeklyReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.yakusokuTheme) private var theme
    @Query(sort: [SortDescriptor(\Commitment.priority)]) 
    private var commitments: [Commitment]
    
    // 모든 체크인 가져오기 (선택된 주에 따라 필터링은 나중에)
    @Query private var allCheckins: [Checkin]
    
    @State private var selectedWeek = 0
    
    private var weekCheckins: [Checkin] {
        let weekKeys = weekDates.map { $0.yakusokuDayKey }
        return allCheckins.filter { checkin in
            weekKeys.contains(checkin.dayKey)
        }
    }
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        // 선택된 주의 시작일 계산
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }
        
        // selectedWeek만큼 이전 주로 이동
        guard let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: -selectedWeek, to: currentWeekStart) else {
            return []
        }
        
        // 해당 주의 7일 생성
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: targetWeekStart)
        }
    }
    
    private var weeklyStats: WeeklyStatistics {
        calculateWeeklyStats()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: YK.Space.lg) {
                    weekSelectorSection
                    overallScoreSection
                    
                    if !commitments.isEmpty {
                        commitmentsSection
                    }
                    
                    insightSection
                    
                    Spacer(minLength: YK.Space.xxl)
                }
                .padding(YK.Space.lg)
            }
            .background(theme.paper.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        TrafficDots(size: 6)
                        Text("주간 리포트")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.ink)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .font(.system(size: 16))
                    .foregroundColor(theme.ink)
                }
            }
        }
        .onChange(of: selectedWeek) { _, newWeek in
            // 주가 변경되면 쿼리 업데이트
            updateWeekQuery(newWeek)
        }
    }
    
    private func updateWeekQuery(_ week: Int) {
        // 선택된 주의 날짜들 계산
        let weekDates = (0..<7).map { Date.daysAgo(6 - $0 - (week * 7)) }
        let weekKeys = weekDates.map { $0.yakusokuDayKey }
        
        // 새로운 필터로 다시 쿼리 (SwiftData가 자동으로 처리)
        // Note: 동적 쿼리 변경은 제한적이므로, 주 변경 시 전체 데이터를 가져와 필터링
    }
    
    private var weekSelectorSection: some View {
        HStack {
            Button {
                selectedWeek += 1
                HapticFeedback.light()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedWeek >= 4 ? theme.inkMuted.opacity(0.4) : theme.ink)
            }
            .disabled(selectedWeek >= 4)
            
            Spacer()
            
            VStack(spacing: YK.Space.xxs) {
                Text(selectedWeek == 0 ? "이번 주" : "\(selectedWeek)주 전")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(theme.ink)
                Text(weekRangeText)
                    .font(.system(size: 12))
                    .foregroundColor(theme.inkMuted)
            }
            
            Spacer()
            
            Button {
                selectedWeek -= 1
                HapticFeedback.light()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedWeek <= 0 ? theme.inkMuted.opacity(0.4) : theme.ink)
            }
            .disabled(selectedWeek <= 0)
        }
        .padding(YK.Space.md)
        .background(theme.paper)
        .overlay(
            RoundedRectangle(cornerRadius: YK.Radius.xl)
                .stroke(theme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: YK.Radius.xl))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private var overallScoreSection: some View {
        theme.card {
            VStack(spacing: YK.Space.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: YK.Space.xs) {
                        Text("나와의 약속 점수")
                            .font(.system(size: 12))
                            .foregroundColor(theme.inkMuted)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(weeklyStats.weekScore)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(theme.ink)
                            Text("%")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(theme.inkMuted)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: YK.Space.xs) {
                        statRow("잘함", count: weeklyStats.goodCount, color: YK.ColorToken.green)
                        statRow("보통", count: weeklyStats.mehCount, color: YK.ColorToken.yellow)
                        statRow("못함", count: weeklyStats.poorCount, color: YK.ColorToken.red)
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.line.opacity(0.3))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(weeklyStats.weekScore >= 80 ? YK.ColorToken.green : 
                                  weeklyStats.weekScore >= 60 ? YK.ColorToken.yellow : YK.ColorToken.red)
                            .frame(width: geometry.size.width * (Double(weeklyStats.weekScore) / 100.0), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
    }
    
    private func statRow(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: YK.Space.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(label): \(count)")
                .font(.system(size: 13))
                .foregroundColor(theme.inkMuted)
        }
    }
    
    private var commitmentsSection: some View {
        VStack(spacing: YK.Space.sm) {
            ForEach(commitments) { commitment in
                CommitmentWeekCard(
                    commitment: commitment,
                    weekDates: weekDates,
                    checkins: checkinsForCommitment(commitment)
                )
            }
        }
    }
    
    private var insightSection: some View {
        theme.card {
            VStack(alignment: .leading, spacing: YK.Space.sm) {
                HStack(spacing: YK.Space.xs) {
                    Image(systemName: insightIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.ink)
                    Text("이번 주 돌아보기")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.ink)
                }
                
                Text(insightText)
                    .font(.system(size: 14))
                    .foregroundColor(theme.inkMuted)
                    .lineSpacing(4)
            }
        }
    }
    
    private var weekRangeText: String {
        let startDate = Date.daysAgo(6 + (selectedWeek * 7))
        let endDate = Date.daysAgo(selectedWeek * 7)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    private var insightText: String {
        if weeklyStats.totalCheckins == 0 {
            return "이번 주는 기록이 없어요. 작은 시작이 큰 변화를 만들어요."
        } else if weeklyStats.weekScore >= 80 {
            return "훌륭해요! 이번 주 목표를 잘 달성했어요. 다음 주도 이 기세를 유지해봐요!"
        } else if weeklyStats.weekScore >= 60 {
            return "좋은 진전이 있었어요! 조금 더 노력하면 더 나은 결과를 얻을 수 있어요."
        } else {
            return "실패는 성공의 어머니예요. If-Then 전략을 다시 점검해보는 건 어떨까요?"
        }
    }
    
    private var insightIcon: String {
        if weeklyStats.totalCheckins == 0 {
            return "sparkles"
        } else if weeklyStats.weekScore >= 80 {
            return "star"
        } else if weeklyStats.weekScore >= 60 {
            return "arrow.up"
        } else {
            return "lightbulb"
        }
    }
    
    private func checkinsForCommitment(_ commitment: Commitment) -> [Checkin] {
        // 현재 선택된 주의 체크인만 필터링
        let weekKeys = weekDates.map { $0.yakusokuDayKey }
        return weekCheckins.filter { checkin in
            checkin.commitmentID == commitment.id &&
            weekKeys.contains(checkin.dayKey)
        }
    }
    
    private func calculateWeeklyStats() -> WeeklyStatistics {
        var totalCheckins = 0
        var goodCount = 0
        var mehCount = 0
        var poorCount = 0
        
        let weekKeys = weekDates.map { $0.yakusokuDayKey }
        
        for commitment in commitments {
            let commitmentCheckins = weekCheckins.filter { checkin in
                checkin.commitmentID == commitment.id &&
                weekKeys.contains(checkin.dayKey)
            }
            totalCheckins += commitmentCheckins.count
            
            for checkin in commitmentCheckins {
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
        
        // 점수 계산 (홈과 동일한 로직 - 실제 체크인한 것들의 평균)
        var totalScore = 0.0
        for checkin in weekCheckins {
            switch checkin.rating {
            case .good: totalScore += 100
            case .meh: totalScore += 50
            case .poor: totalScore += 20
            }
        }
        let weekScore = totalCheckins > 0 ? Int(totalScore / Double(totalCheckins)) : 0
        
        return WeeklyStatistics(
            totalCheckins: totalCheckins,
            goodCount: goodCount,
            mehCount: mehCount,
            poorCount: poorCount,
            completionRate: completionRate,
            successRate: successRate,
            weekScore: weekScore
        )
    }
}

struct CommitmentWeekCard: View {
    @Environment(\.yakusokuTheme) private var theme
    let commitment: Commitment
    let weekDates: [Date]
    let checkins: [Checkin]
    
    private func ratingForDate(_ date: Date) -> Rating? {
        checkins.first { $0.dayKey == date.yakusokuDayKey }?.rating
    }
    
    var body: some View {
        theme.card {
            VStack(alignment: .leading, spacing: YK.Space.sm) {
                Text(commitment.title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(theme.ink)
                
                HStack(spacing: YK.Space.xs) {
                    ForEach(weekDates, id: \.self) { date in
                        VStack(spacing: YK.Space.xxs) {
                            Text(date.weekdayString)
                                .font(.system(size: 10))
                                .foregroundColor(theme.inkMuted.opacity(0.7))
                            
                            if let rating = ratingForDate(date) {
                                Circle()
                                    .fill(colorForRating(rating))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Image(systemName: iconForRating(rating))
                                            .font(.system(size: 12, weight: .light))
                                            .foregroundColor(.white)
                                    )
                            } else {
                                Circle()
                                    .stroke(theme.line, lineWidth: 1)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func colorForRating(_ rating: Rating) -> Color {
        switch rating {
        case .good: return YK.ColorToken.green
        case .meh: return YK.ColorToken.yellow
        case .poor: return YK.ColorToken.red
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

struct WeeklyStatistics {
    let totalCheckins: Int
    let goodCount: Int
    let mehCount: Int
    let poorCount: Int
    let completionRate: Double
    let successRate: Double
    let weekScore: Int
}

#Preview {
    WeeklyReportView()
        .environment(\.yakusokuTheme, MinimalRetroTheme())
        .modelContainer(for: [Commitment.self, Checkin.self])
}