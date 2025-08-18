import SwiftUI
import SwiftData
import Charts

struct CommitmentDetailView: View {
    let commitment: Commitment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allCheckins: [Checkin]
    
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    
    private var checkins: [Checkin] {
        allCheckins
            .filter { $0.commitmentID == commitment.id }
            .sorted { $0.date > $1.date }
    }
    
    private var last14DaysCheckins: [DailyScore] {
        var scores: [DailyScore] = []
        
        for day in 0..<14 {
            let date = Date.daysAgo(13 - day)
            let dayKey = date.yakusokuDayKey
            let checkin = checkins.first { $0.dayKey == dayKey }
            
            scores.append(DailyScore(
                date: date,
                rating: checkin?.rating,
                score: checkin?.rating.score ?? 0
            ))
        }
        
        return scores
    }
    
    private var weeklyScore: Double {
        let recentScores = last14DaysCheckins
            .suffix(7)
            .compactMap { $0.rating?.score }
        
        guard !recentScores.isEmpty else { return 0 }
        return recentScores.reduce(0, +) / Double(recentScores.count)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(commitment.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let pros = commitment.pros, !pros.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("지켰을 때", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                
                                Text(pros)
                                    .font(.body)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.green.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        if let cons = commitment.cons, !cons.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("어겼을 때", systemImage: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                
                                Text(cons)
                                    .font(.body)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        if let ifThen = commitment.ifThen, !ifThen.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("If-Then 전략", systemImage: "arrow.right.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                
                                Text(ifThen)
                                    .font(.body)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("최근 14일 기록")
                                .font(.headline)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(weeklyScore * 100))%")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("주간 달성률")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Chart(last14DaysCheckins) { item in
                            BarMark(
                                x: .value("날짜", item.date),
                                y: .value("점수", item.score)
                            )
                            .foregroundStyle(item.color)
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                        .chartYScale(domain: 0...1)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(date.weekdayString)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: [0, 0.5, 1]) { value in
                                if let score = value.as(Double.self) {
                                    AxisValueLabel {
                                        Text(ratingLabel(for: score))
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("약속 삭제", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("약속 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("편집") {
                        showingEditView = true
                    }
                }
            }
            .alert("약속 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    deleteCommitment()
                }
            } message: {
                Text("이 약속과 관련된 모든 기록이 삭제됩니다.")
            }
            .sheet(isPresented: $showingEditView) {
                EditCommitmentView(commitment: commitment)
            }
        }
    }
    
    private func deleteCommitment() {
        modelContext.delete(commitment)
        
        let checkinsToDelete = checkins
        checkinsToDelete.forEach { modelContext.delete($0) }
        
        try? modelContext.save()
        dismiss()
    }
    
    private func ratingLabel(for score: Double) -> String {
        switch score {
        case 0: return "😣"
        case 0.5: return "😐"
        case 1: return "🙂"
        default: return ""
        }
    }
}

struct DailyScore: Identifiable {
    let id = UUID()
    let date: Date
    let rating: Rating?
    let score: Double
    
    var color: Color {
        switch rating {
        case .good: return .green
        case .meh: return .orange
        case .poor: return .red
        case nil: return .secondary.opacity(0.2)
        }
    }
}

extension Rating {
    var score: Double {
        switch self {
        case .poor: return 0
        case .meh: return 0.5
        case .good: return 1
        }
    }
}