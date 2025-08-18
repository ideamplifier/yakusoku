import SwiftUI

// MARK: - v2 Color Tokens
struct MColor {
    static let ink = Color(hex: "#2C2C2E")  // 더 부드러운 다크 그레이
    static let surface = Color.white
    static let background = Color(hex: "#F2F2F7")  // 연한 그레이 배경
    static let red = Color(hex: "#FF3B30")  // 시스템 레드
    static let yellow = Color(hex: "#FFCC00")  // 시스템 옐로우
    static let green = Color(hex: "#34C759")  // 시스템 그린
    
    static let border = Color(hex: "#E5E5EA")  // 연한 그레이 보더
    static let strokeSubtle = ink.opacity(0.15)
    static let grayDots = Color(hex: "#C7C7CC")  // 연한 그레이 닷
    static let secondaryText = Color(hex: "#8E8E93")  // 시스템 그레이
    static let tertiaryText = Color(hex: "#C7C7CC")  // 더 연한 그레이
}

// MARK: - WidgetBlock Component
struct WidgetBlock<Content: View>: View {
    var corner: CGFloat = 18
    var content: () -> Content
    
    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(MColor.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - AccentBadge
struct AccentBadge: View {
    var text: String
    var color: Color
    
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .kerning(0.2)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(color.opacity(0.16))
            .foregroundStyle(MColor.ink)
            .clipShape(Capsule())
    }
}

// MARK: - ProgressCapsule
struct ProgressCapsule: View {
    var value: CGFloat // 0...1
    var color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(MColor.border.opacity(0.5))
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * max(0, min(1, value)))
            }
        }
        .frame(height: 10)
    }
}

// MARK: - DotCalendar
struct DotCalendar: View {
    var completion: [Bool?] // nil = no data, true = completed, false = failed
    var accentGood: Color = MColor.green
    var accentBad: Color = MColor.red
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(completion.indices, id: \.self) { i in
                Circle()
                    .fill(
                        completion[i] == true ? MColor.ink :
                        completion[i] == false ? MColor.red.opacity(0.6) :
                        MColor.grayDots
                    )
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - MinimalScorePicker
enum ScoreMini: String, CaseIterable {
    case poor = "못함"
    case mid = "보통"
    case good = "잘함"
    
    var color: Color {
        switch self {
        case .poor: return MColor.red
        case .mid: return MColor.yellow
        case .good: return MColor.green
        }
    }
    
    // Rating enum과 매핑
    init(from rating: Rating?) {
        switch rating {
        case .poor: self = .poor
        case .meh: self = .mid
        case .good: self = .good
        case nil: self = .mid
        }
    }
    
    var toRating: Rating {
        switch self {
        case .poor: return .poor
        case .mid: return .meh
        case .good: return .good
        }
    }
}

struct MinimalScorePicker: View {
    @Binding var selection: ScoreMini
    
    var body: some View {
        ZStack {
            // 토글 스타일 배경
            Capsule()
                .fill(backgroundColorForSelection)
            
            GeometryReader { geo in
                let inset: CGFloat = 2
                let knobSize = geo.size.height - inset * 2
                let totalWidth = geo.size.width - inset * 2 - knobSize
                let x: CGFloat = inset + {
                    switch selection {
                    case .poor: return 0
                    case .mid: return totalWidth / 2
                    case .good: return totalWidth
                    }
                }()
                
                // 토글 노브
                Circle()
                    .fill(Color.white)
                    .frame(width: knobSize, height: knobSize)
                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                    .offset(x: x, y: inset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selection)
            }
            
            HStack(spacing: 0) {
                segmentLabel("못함", score: .poor)
                segmentLabel("보통", score: .mid)
                segmentLabel("잘함", score: .good)
            }
        }
        .frame(height: 32)
    }
    
    private var backgroundColorForSelection: Color {
        switch selection {
        case .poor: return MColor.red.opacity(0.8)
        case .mid: return MColor.yellow.opacity(0.8)
        case .good: return MColor.green
        }
    }
    
    private func segmentLabel(_ text: String, score: ScoreMini) -> some View {
        Text("")  // 텍스트 숨김 - 토글 스타일에서는 레이블 불필요
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selection = score
                    HapticFeedback.light()
                }
            }
    }
}

// MARK: - Date Widget Helper
struct DateWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(todayFormatted("E MMM"))
                .font(.caption)
                .foregroundStyle(MColor.secondaryText)
            Text(todayFormatted("d"))
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(MColor.ink)
        }
    }
    
    private func todayFormatted(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = format
        return formatter.string(from: Date())
    }
}

// MARK: - Week Progress Widget
struct WeekProgressWidget: View {
    let progress: CGFloat
    let completed: Int
    let total: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("이번 주")
                    .font(.caption)
                    .foregroundStyle(MColor.secondaryText)
                Spacer()
                AccentBadge(
                    text: "\(completed)/\(total)",
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

// MARK: - Commitment Widget
struct CommitmentWidget: View {
    let commitment: Commitment
    @Binding var score: ScoreMini
    let weekDots: [Bool?]
    var onTap: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(commitment.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MColor.ink)
                    .lineLimit(2)
                
                DotCalendar(completion: weekDots)
            }
            
            MinimalScorePicker(selection: $score)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}