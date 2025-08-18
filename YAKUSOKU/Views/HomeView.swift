import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Commitment.priority)]) 
    private var commitments: [Commitment]
    @Query private var checkins: [Checkin]
    
    @State private var showingAddCommitment = false
    @State private var showingWeeklyReport = false
    @State private var showingSettings = false
    @State private var selectedCommitment: Commitment?
    
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }
    
    private var todayCheckinCount: Int {
        let todayKey = Date().yakusokuDayKey
        return checkins.filter { $0.dayKey == todayKey }.count
    }
    
    private var todayProgress: Double {
        guard !commitments.isEmpty else { return 0 }
        return Double(todayCheckinCount) / Double(commitments.count)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 크림 배경
                YKColor.cream
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 헤더
                        VStack(spacing: 8) {
                            Text("YAKUSOKU")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .kerning(-0.3)
                                .foregroundStyle(YKColor.ink)
                            
                            Text(todayString)
                                .font(.caption)
                                .foregroundStyle(YKColor.secondaryText)
                        }
                        .padding(.top, 20)
                        
                        // 오늘의 진행률
                        if !commitments.isEmpty {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("오늘의 약속")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(YKColor.ink)
                                    
                                    Spacer()
                                    
                                    RetroTag(
                                        text: "\(todayCheckinCount)/\(commitments.count)",
                                        color: progressColor
                                    )
                                }
                                
                                // 캡슐형 단색 진행바
                                GeometryReader { geo in
                                    Capsule()
                                        .fill(progressColor.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(progressColor)
                                        .frame(width: geo.size.width * todayProgress, height: 8)
                                }
                                .frame(height: 8)
                            }
                            .stickerCard()
                        }
                        
                        // 약속 카드들
                        if commitments.isEmpty {
                            EmptyStateView(showingAddCommitment: $showingAddCommitment)
                        } else {
                            ForEach(commitments) { commitment in
                                CommitmentCard(commitment: commitment)
                                    .onTapGesture {
                                        selectedCommitment = commitment
                                    }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingWeeklyReport = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(YKColor.ink)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(YKColor.ink)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Floating Action Button
                Button {
                    showingAddCommitment = true
                    HapticFeedback.medium()
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                }
                .retroFloatingButton()
                .padding(24)
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
    
    private var progressColor: Color {
        if todayProgress >= 0.8 {
            return YKColor.green
        } else if todayProgress >= 0.5 {
            return YKColor.yellow
        } else {
            return YKColor.red
        }
    }
}

struct EmptyStateView: View {
    @Binding var showingAddCommitment: Bool
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(YKColor.yellow)
                .scaleEffect(animateIcon ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
                .onAppear { animateIcon = true }
            
            VStack(spacing: 8) {
                Text("첫 약속을 만들어보세요")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(YKColor.ink)
                
                Text("오늘부터 시작하는 작은 변화")
                    .font(.caption)
                    .foregroundStyle(YKColor.secondaryText)
            }
            
            Button {
                showingAddCommitment = true
                HapticFeedback.medium()
            } label: {
                Text("약속 만들기")
                    .font(.headline.weight(.bold))
                    .kerning(0.2)
            }
            .retroButton(.green)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .stickerCard()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Commitment.self, Checkin.self])
}