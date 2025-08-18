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
        VStack(alignment: .leading, spacing: 18) {
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
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(
                                LinearGradient(
                                    colors: [ZenColors.tertiaryGreen.opacity(0.3), ZenColors.tertiaryGreen.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        .zenCard()
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
            HapticFeedback.light()
        } label: {
            VStack(spacing: 4) {
                // 플랫 디자인 이모지 사용
                FluentEmoji(rating: rating, size: 28)
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .opacity(isSelected ? 1.0 : 0.7)
                
                if isSelected {
                    Circle()
                        .fill(colorForRating(rating))
                        .frame(width: 5, height: 5)
                }
            }
            .frame(width: 52, height: 52)
        }
        .zenButton(isSelected: isSelected, selectionColor: colorForRating(rating))
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
    
    private func colorForRating(_ rating: Rating) -> Color {
        switch rating {
        case .good:
            return ZenColors.goodColor
        case .meh:
            return ZenColors.mehColor
        case .poor:
            return ZenColors.poorColor
        }
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
            return ZenColors.goodColor
        case .meh:
            return ZenColors.mehColor
        case .poor:
            return ZenColors.poorColor
        case nil:
            return ZenColors.tertiaryText.opacity(0.2)
        }
    }
}