import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.yakusokuTheme) private var theme
    @Query(sort: [SortDescriptor(\Commitment.priority)]) 
    private var commitments: [Commitment]
    
    // 오늘 체크인만 쿼리 (성능 최적화)
    @Query private var todayCheckins: [Checkin]
    
    // 이번 주 체크인 쿼리
    @Query private var weekCheckins: [Checkin]
    
    @State private var showingAddCommitment = false
    @State private var showingWeeklyReport = false
    @State private var showingSettings = false
    @State private var selectedTab = 0
    @State private var selectedCommitment: Commitment?
    
    init() {
        let todayKey = Date().yakusokuDayKey
        _todayCheckins = Query(
            filter: #Predicate<Checkin> { checkin in
                checkin.dayKey == todayKey
            }
        )
        
        // 이번 주 체크인 쿼리
        let sevenDaysAgo = Date.daysAgo(7)
        _weekCheckins = Query(
            filter: #Predicate<Checkin> { checkin in
                checkin.date >= sevenDaysAgo
            }
        )
    }
    
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }
    
    private var weekScore: Int {
        if commitments.isEmpty { return 0 }
        
        // 체크인 점수 계산
        var totalScore = 0.0
        var checkinCount = 0
        
        for checkin in weekCheckins {
            checkinCount += 1
            switch checkin.rating {
            case .good: 
                totalScore += 100
            case .meh: 
                totalScore += 50
            case .poor: 
                totalScore += 20
            }
        }
        
        // 실제 체크인한 약속 개수로 나누기
        if checkinCount == 0 { return 0 }
        
        // 체크인한 것들의 평균 점수
        return Int(totalScore / Double(checkinCount))
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
                        .padding(.bottom, 100) // 탭바 높이 + 여유 공간
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
        .sheet(item: $selectedCommitment) { commitment in
            CommitmentDetailModalView(commitment: commitment)
                .presentationDetents([.medium])
                .presentationCornerRadius(28)
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color(hex: "#F9F7F4"))
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: YK.Space.md) {
            ZStack {
                // 가운데 정렬된 YAKUSOKU
                Text("YAKUSOKU")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(theme.ink)
                    .tracking(1)
                
                // 오른쪽 끝에 + 버튼
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddCommitment = true
                        HapticFeedback.light()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(theme.ink)
                    }
                }
            }
            
            Text(todayString)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(theme.ink)
                .frame(maxWidth: .infinity)
                .offset(y: -5)
        }
    }
    
    private var weekProgressCard: some View {
        YKWeekProgress(weekScore: weekScore)
    }
    
    private var commitmentsSection: some View {
        VStack(spacing: YK.Space.sm) {
            ForEach(commitments) { commitment in
                theme.card {
                    CommitmentRowContent(
                        commitment: commitment,
                        todayCheckins: todayCheckins,
                        onRowTap: {
                            selectedCommitment = commitment
                            HapticFeedback.light()
                        }
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
    let onRowTap: () -> Void
    
    @Query private var weekCheckins: [Checkin]
    
    init(commitment: Commitment, todayCheckins: [Checkin], onRowTap: @escaping () -> Void) {
        self.commitment = commitment
        self.todayCheckins = todayCheckins
        self.onRowTap = onRowTap
        
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
            commitment: commitment,
            weekDots: weekDots,
            todayRating: todayRating,
            onRatingTap: { rating in
                performCheckin(rating: rating)
            },
            onRowTap: onRowTap
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

// MARK: - Commitment Detail Modal
struct CommitmentDetailModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.yakusokuTheme) private var theme
    let commitment: Commitment
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 50)
            
            ScrollView {
                VStack(alignment: .leading, spacing: YK.Space.lg) {
                    // Title
                    Text(commitment.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(theme.ink)
                    
                    // Pros
                    if let pros = commitment.pros, !pros.isEmpty {
                        VStack(alignment: .leading, spacing: YK.Space.xs) {
                            Text("장점")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.ink)
                            Text(pros)
                                .font(.system(size: 14))
                                .foregroundColor(theme.inkMuted)
                        }
                    }
                    
                    // Cons
                    if let cons = commitment.cons, !cons.isEmpty {
                        VStack(alignment: .leading, spacing: YK.Space.xs) {
                            Text("단점")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.ink)
                            Text(cons)
                                .font(.system(size: 14))
                                .foregroundColor(theme.inkMuted)
                        }
                    }
                    
                    // If-Then
                    if let ifThen = commitment.ifThen, !ifThen.isEmpty {
                        VStack(alignment: .leading, spacing: YK.Space.xs) {
                            Text("실행 계획")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.ink)
                            Text(ifThen)
                                .font(.system(size: 14))
                                .foregroundColor(theme.inkMuted)
                        }
                    }
                    
                    Spacer()
                }
                .padding(YK.Space.lg)
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(\.yakusokuTheme, MinimalRetroTheme())
        .modelContainer(for: [Commitment.self, Checkin.self])
}