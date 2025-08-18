import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.yakusokuTheme) private var theme
    @Query(sort: [SortDescriptor(\Commitment.priority)]) 
    private var commitments: [Commitment]
    
    // 오늘 체크인만 쿼리 (성능 최적화)
    @Query private var todayCheckins: [Checkin]
    
    @State private var showingAddCommitment = false
    @State private var showingWeeklyReport = false
    @State private var showingSettings = false
    @State private var selectedTab = 0
    
    init() {
        let todayKey = Date().yakusokuDayKey
        _todayCheckins = Query(
            filter: #Predicate<Checkin> { checkin in
                checkin.dayKey == todayKey
            }
        )
    }
    
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }
    
    private var todayProgress: (completed: Int, total: Int, successRate: Double) {
        let completed = todayCheckins.count
        let total = commitments.count
        let goodCount = todayCheckins.filter { $0.rating == .good }.count
        let successRate = completed > 0 ? Double(goodCount) / Double(completed) : 0
        return (completed, total, successRate)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.paper.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal, YK.Space.lg)
                        .padding(.top, YK.Space.md)
                        .padding(.bottom, YK.Space.lg)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: YK.Space.md) {
                            if commitments.isEmpty {
                                emptyStateSection
                            } else {
                                weekProgressCard
                                commitmentsSection
                            }
                        }
                        .padding(.horizontal, YK.Space.lg)
                        .padding(.bottom, 20)
                    }
                }
                
                // Bottom Tab Bar
                VStack {
                    Spacer()
                    bottomTabBar
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddCommitment) {
            AddCommitmentView()
        }
        .sheet(isPresented: $showingWeeklyReport) {
            WeeklyReportView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: YK.Space.sm) {
            HStack {
                TrafficDots()
                Spacer()
                Text("YAKUSOKU")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(theme.ink)
                    .tracking(1)
                Spacer()
                // 약속 추가 버튼
                Button(action: {
                    showingAddCommitment = true
                    HapticFeedback.light()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.ink)
                }
            }
            
            Text(todayString)
                .font(.system(size: 14))
                .foregroundColor(theme.inkMuted)
            
            Text("오늘의 약속")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(theme.ink)
        }
    }
    
    private var weekProgressCard: some View {
        theme.card {
            YKWeekProgress(
                completed: todayProgress.completed,
                total: todayProgress.total,
                successRate: todayProgress.successRate
            )
        }
    }
    
    private var commitmentsSection: some View {
        VStack(spacing: YK.Space.sm) {
            ForEach(commitments) { commitment in
                theme.card {
                    CommitmentRowContent(
                        commitment: commitment,
                        todayCheckins: todayCheckins
                    )
                }
            }
        }
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: YK.Space.xl) {
            Spacer()
            
            VStack(spacing: YK.Space.md) {
                TrafficDots(size: 16)
                
                VStack(spacing: YK.Space.xs) {
                    Text("첫 약속을 만들어보세요")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.ink)
                    
                    Text("작은 약속이 큰 변화를 만듭니다")
                        .font(.system(size: 14))
                        .foregroundColor(theme.inkMuted)
                }
                
                Text("상단 + 버튼을 눌러 시작하세요")
                    .font(.system(size: 12))
                    .foregroundColor(theme.inkMuted.opacity(0.6))
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
    
    private var bottomTabBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(theme.line)
            
            HStack(spacing: 0) {
                TabBarButton(
                    icon: "house.fill",
                    title: "홈",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
                TabBarButton(
                    icon: "chart.bar.fill",
                    title: "리포트",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                    showingWeeklyReport = true
                }
                
                TabBarButton(
                    icon: "gearshape.fill",
                    title: "설정",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                    showingSettings = true
                }
            }
            .padding(.top, YK.Space.xs)
            .padding(.bottom, YK.Space.md)
        }
        .background(theme.paper)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    @Environment(\.yakusokuTheme) private var theme
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 11))
            }
            .foregroundColor(isSelected ? theme.ink : theme.inkMuted.opacity(0.6))
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Commitment Row Content
struct CommitmentRowContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.yakusokuTheme) private var theme
    
    let commitment: Commitment
    let todayCheckins: [Checkin]
    
    @Query private var weekCheckins: [Checkin]
    
    init(commitment: Commitment, todayCheckins: [Checkin]) {
        self.commitment = commitment
        self.todayCheckins = todayCheckins
        
        // 이번 주 체크인만 쿼리
        let commitmentID = commitment.id
        let sevenDaysAgo = Date.daysAgo(7)
        
        _weekCheckins = Query(
            filter: #Predicate<Checkin> { checkin in
                checkin.commitmentID == commitmentID &&
                checkin.date >= sevenDaysAgo
            }
        )
    }
    
    private var todayRating: Rating? {
        todayCheckins.first { $0.commitmentID == commitment.id }?.rating
    }
    
    private var weekDots: [Rating?] {
        (0..<7).map { day in
            let date = Date.daysAgo(6 - day)
            let dayKey = date.yakusokuDayKey
            return weekCheckins.first { $0.dayKey == dayKey }?.rating
        }
    }
    
    var body: some View {
        YKCommitmentRow(
            title: commitment.title,
            subtitle: commitment.ifThen,
            weekDots: weekDots,
            todayRating: todayRating,
            onRatingTap: { rating in
                performCheckin(rating: rating)
            }
        )
    }
    
    private func performCheckin(rating: Rating) {
        let dayKey = Date().yakusokuDayKey
        let commitmentID = commitment.id
        
        // 중복 방지
        var descriptor = FetchDescriptor<Checkin>(
            predicate: #Predicate { checkin in
                checkin.commitmentID == commitmentID && checkin.dayKey == dayKey
            }
        )
        descriptor.fetchLimit = 1
        
        if let existingCheckin = try? modelContext.fetch(descriptor).first {
            if existingCheckin.rating == rating {
                // 같은 평가 다시 탭하면 삭제 (토글)
                modelContext.delete(existingCheckin)
            } else {
                // 다른 평가로 변경
                existingCheckin.rating = rating
                existingCheckin.date = Date()
            }
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
        
        // Haptic feedback
        switch rating {
        case .good: HapticFeedback.success()
        case .meh: HapticFeedback.light()
        case .poor: HapticFeedback.warning()
        }
    }
}

#Preview {
    HomeView()
        .environment(\.yakusokuTheme, MinimalRetroTheme())
        .modelContainer(for: [Commitment.self, Checkin.self])
}