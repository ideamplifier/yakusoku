import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Commitment.priority)]) 
    private var commitments: [Commitment]
    
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if commitments.isEmpty {
                    EmptyStateView(showingAddCommitment: $showingAddCommitment)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(commitments) { commitment in
                                CommitmentCard(commitment: commitment)
                                    .onTapGesture {
                                        selectedCommitment = commitment
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("YAKUSOKU")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(todayString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showingWeeklyReport = true
                        } label: {
                            Image(systemName: "chart.bar")
                        }
                        
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        
                        Button {
                            showingAddCommitment = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
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
}

struct EmptyStateView: View {
    @Binding var showingAddCommitment: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            
            VStack(spacing: 8) {
                Text("작은 약속이 하루를 바꿔요")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("첫 번째 약속을 만들어보세요")
                    .foregroundStyle(.secondary)
            }
            
            Button {
                showingAddCommitment = true
            } label: {
                Label("약속 만들기", systemImage: "plus.circle.fill")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Commitment.self, Checkin.self])
}