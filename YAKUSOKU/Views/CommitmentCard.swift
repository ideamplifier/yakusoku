import SwiftUI
import SwiftData

struct CommitmentCard: View {
    let commitment: Commitment
    @Environment(\.modelContext) private var modelContext
    @Query private var checkins: [Checkin]
    
    @State private var todayCheckin: Checkin?
    @State private var showingIfThen = false
    
    private var todayKey: String {
        Date().yakusokuDayKey
    }
    
    private var todayRating: Rating? {
        checkins.first { 
            $0.commitmentID == commitment.id && 
            $0.dayKey == todayKey 
        }?.rating
    }
    
    private var recentCheckins: [Checkin] {
        let sevenDaysAgo = Date.daysAgo(7)
        return checkins
            .filter { $0.commitmentID == commitment.id && $0.date >= sevenDaysAgo }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(commitment.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let ifThen = commitment.ifThen, !ifThen.isEmpty {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            showingIfThen.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showingIfThen ? "chevron.up.circle" : "chevron.down.circle")
                                .font(.caption)
                            Text("If-Then 전략")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    if showingIfThen {
                        Text(ifThen)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            
            HStack(spacing: 12) {
                SevenDayIndicator(checkins: recentCheckins)
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(Rating.allCases, id: \.self) { rating in
                        CheckinButton(
                            rating: rating,
                            isSelected: todayRating == rating,
                            commitment: commitment
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct CheckinButton: View {
    let rating: Rating
    let isSelected: Bool
    let commitment: Commitment
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Button {
            performCheckin()
        } label: {
            VStack(spacing: 4) {
                Text(rating.emoji)
                    .font(.title2)
                
                if isSelected {
                    Circle()
                        .fill(.tint)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 44, height: 44)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func performCheckin() {
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
    }
}

struct SevenDayIndicator: View {
    let checkins: [Checkin]
    
    private func ratingForDay(_ day: Int) -> Rating? {
        let date = Date.daysAgo(6 - day)
        let dayKey = date.yakusokuDayKey
        return checkins.first { $0.dayKey == dayKey }?.rating
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<7) { day in
                VStack(spacing: 2) {
                    Circle()
                        .fill(colorForRating(ratingForDay(day)))
                        .frame(width: 8, height: 8)
                    
                    Text(dayLabel(day))
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func dayLabel(_ day: Int) -> String {
        let date = Date.daysAgo(6 - day)
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ko_KR")
        return String(formatter.string(from: date).prefix(1))
    }
    
    private func colorForRating(_ rating: Rating?) -> Color {
        switch rating {
        case .good:
            return .green
        case .meh:
            return .orange
        case .poor:
            return .red
        case nil:
            return .secondary.opacity(0.2)
        }
    }
}