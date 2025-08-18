import SwiftUI
import SwiftData

struct HomeMinimalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Commitment.priority)]) 
    private var commitments: [Commitment]
    @Query private var checkins: [Checkin]
    
    @State private var showingAddCommitment = false
    @State private var showingWeeklyReport = false
    @State private var showingSettings = false
    @State private var selectedCommitment: Commitment?
    
    private var todayKey: String {
        Date().yakusokuDayKey
    }
    
    private var todayProgress: (completed: Int, total: Int, rate: CGFloat) {
        let todayCheckins = checkins.filter { $0.dayKey == todayKey }
        let completed = todayCheckins.count
        let total = commitments.count
        let rate = total > 0 ? CGFloat(completed) / CGFloat(total) : 0
        return (completed, total, rate)
    }
    
    private var weekProgress: (completed: Int, total: Int, rate: CGFloat) {
        let weekDates = (0..<7).map { Date.daysAgo(6 - $0) }
        let weekKeys = weekDates.map { $0.yakusokuDayKey }
        let weekCheckins = checkins.filter { weekKeys.contains($0.dayKey) }
        let completed = weekCheckins.count
        let total = commitments.count * 7
        let rate = total > 0 ? CGFloat(completed) / CGFloat(total) : 0
        return (completed, total, rate)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 상단 2열: 날짜 / 주간 진행률
                    HStack(spacing: 12) {
                        WidgetBlock {
                            DateWidget()
                        }
                        
                        WidgetBlock {
                            WeekProgressWidget(
                                progress: weekProgress.rate,
                                completed: weekProgress.completed,
                                total: weekProgress.total
                            )
                        }
                    }
                    
                    // 오늘의 진행률 (전체 폭)
                    if !commitments.isEmpty {
                        WidgetBlock {
                            TodayProgressWidget(
                                progress: todayProgress.rate,
                                completed: todayProgress.completed,
                                total: todayProgress.total
                            )
                        }
                    }
                    
                    // 약속 카드들
                    if commitments.isEmpty {
                        WidgetBlock {
                            EmptyStateWidget(showingAddCommitment: $showingAddCommitment)
                        }
                    } else {
                        ForEach(commitments) { commitment in
                            WidgetBlock {
                                CommitmentMinimalCard(
                                    commitment: commitment,
                                    checkins: checkinsForCommitment(commitment)
                                ) {
                                    selectedCommitment = commitment
                                }
                            }
                        }
                    }
                    
                    // 하단 여백
                    Spacer(minLength: 80)
                }
                .padding(16)
            }
            .background(MColor.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("YAKUSOKU")
                        .font(.headline.weight(.black))
                        .foregroundStyle(MColor.ink)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingWeeklyReport = true
                    } label: {
                        Image(systemName: "chart.bar")
                            .foregroundStyle(MColor.ink)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(MColor.ink)
                        }
                        
                        Button {
                            showingAddCommitment = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(MColor.ink)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "plus")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddCommitment) {
                AddCommitmentView()
            }
            .sheet(item: $selectedCommitment) { commitment in
                CommitmentDetailView(commitment: commitment)
            }
            .sheet(isPresented: $showingWeeklyReport) {
                WeeklyReportView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private func checkinsForCommitment(_ commitment: Commitment) -> [Checkin] {
        let sevenDaysAgo = Date.daysAgo(7)
        return checkins
            .filter { $0.commitmentID == commitment.id && $0.date >= sevenDaysAgo }
            .sorted { $0.date > $1.date }
    }
}

// MARK: - Today Progress Widget
struct TodayProgressWidget: View {
    let progress: CGFloat
    let completed: Int
    let total: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("오늘의 약속")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MColor.ink)
                    
                    Text("\(completed)개 완료")
                        .font(.caption)
                        .foregroundStyle(MColor.secondaryText)
                }
                
                Spacer()
                
                AccentBadge(
                    text: "\(Int(progress * 100))%",
                    color: progress > 0.7 ? MColor.green : progress > 0.3 ? MColor.yellow : MColor.red
                )
            }
            
            ProgressCapsule(
                value: progress,
                color: progress > 0.7 ? MColor.green : progress > 0.3 ? MColor.yellow : MColor.red
            )
        }
    }
}

// MARK: - Commitment Minimal Card
struct CommitmentMinimalCard: View {
    let commitment: Commitment
    let checkins: [Checkin]
    var onTap: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var currentScore: ScoreMini = .mid
    
    private var todayKey: String {
        Date().yakusokuDayKey
    }
    
    private var todayRating: Rating? {
        checkins.first { $0.dayKey == todayKey }?.rating
    }
    
    private var weekDots: [Bool?] {
        (0..<7).map { day in
            let date = Date.daysAgo(6 - day)
            let dayKey = date.yakusokuDayKey
            if let checkin = checkins.first(where: { $0.dayKey == dayKey }) {
                switch checkin.rating {
                case .good: return true
                case .meh, .poor: return false
                }
            }
            return nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(commitment.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(MColor.ink)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        DotCalendar(completion: weekDots)
                        Spacer()
                        Text(currentScore.rawValue)
                            .font(.caption)
                            .foregroundStyle(MColor.secondaryText)
                    }
                }
                
                Spacer()
                
                MinimalScorePicker(selection: .init(
                    get: { ScoreMini(from: todayRating) },
                    set: { newScore in
                        performCheckin(rating: newScore.toRating)
                    }
                ))
                .frame(width: 80)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear {
            currentScore = ScoreMini(from: todayRating)
        }
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
        HapticFeedback.light()
    }
}

// MARK: - Empty State Widget
struct EmptyStateWidget: View {
    @Binding var showingAddCommitment: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(MColor.secondaryText)
            
            VStack(spacing: 8) {
                Text("작은 약속이 하루를 바꿔요")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MColor.ink)
                
                Text("첫 번째 약속을 만들어보세요")
                    .font(.caption)
                    .foregroundStyle(MColor.secondaryText)
            }
            
            Button {
                showingAddCommitment = true
                HapticFeedback.medium()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("약속 만들기")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(MColor.ink)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(MColor.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

#Preview {
    HomeMinimalView()
        .modelContainer(for: [Commitment.self, Checkin.self])
}